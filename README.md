# Logistics Data Platform — AWS S3, Snowflake & dbt

## Présentation

Ce projet met en place une plateforme Data Engineering orientée **logistique / Supply Chain**, à partir du dataset **DataCo Supply Chain**.

Le flux construit est volontairement simple et reproductible :

**DataCo CSV → AWS S3 → Snowflake → dbt → Bronze / Silver / Gold**

Le projet met en pratique le stockage objet, le Data Warehouse cloud, SQL, la transformation ELT avec dbt (développé et exécuté via **dbt Cloud**), la modélisation, les tests de qualité, ainsi que le versionnement et la documentation avec Git/GitHub.

---

## Architecture

```text
                         DataCo CSV
                             │
                             ▼
                          AWS S3
                             │
                             ▼
                         Snowflake
                             │
                             ▼
                    ┌─────────────────┐
                    │     BRONZE      │
                    │ Données brutes  │
                    │   180 519 lignes│
                    │   53 colonnes   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │     SILVER      │
                    │ Nettoyage       │
                    │ Typage          │
                    │ Standardisation │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │      GOLD       │
                    │ Modèles métier  │
                    │ Agrégations     │
                    └─────────────────┘
```

### Stack

| Technologie | Utilisation |
|---|---|
| **AWS S3** | Stockage du fichier source |
| **Snowflake** | Data Warehouse |
| **SQL** | Ingestion, transformation et contrôles |
| **dbt Cloud** | Transformation, modélisation et tests |
| **Git / GitHub** | Versionnement et documentation |

---

## 1. Source & ingestion

La source utilisée est le dataset public **DataCo Supply Chain**.

Le fichier est déposé dans un bucket S3 privé :

```text
logistics-data-platform-ahmed/
└── raw/
    └── dataco/
        └── DataCoSupplyChainDataset.csv
```

Snowflake accède au bucket grâce à une **Storage Integration** et à un rôle IAM AWS disposant des droits nécessaires à la lecture des données RAW.

### Snowflake — accès au bucket

```sql
CREATE STAGE IF NOT EXISTS STAGE_DATACO
    URL = 's3://logistics-data-platform-ahmed/raw/dataco/'
    STORAGE_INTEGRATION = LOGISTIC_S3_INT
    FILE_FORMAT = FF_DATACO_CSV;

LIST @STAGE_DATACO;
```

Le fichier source contient **53 colonnes** et environ **180 519 lignes**.

---

## 2. Architecture Snowflake

```text
LOGISTIC_DWH
│
├── BRONZE
│   └── RAW_DATACO
│
├── SILVER
│   ├── client
│   ├── produit
│   ├── departement
│   ├── localisation
│   ├── livraison
│   └── commande
│
└── GOLD
    ├── ventes
    ├── performance_livraison
    └── performance_produit
```

Le warehouse Snowflake utilisé est dimensionné en **X-SMALL**, avec suspension automatique après inactivité afin de limiter la consommation de crédits.

---

## 3. Bronze — conserver la donnée source

La couche Bronze constitue le point d'entrée dans Snowflake. La donnée source est conservée au plus proche de son format initial.

Les colonnes de `RAW_DATACO` sont chargées en `VARCHAR` afin de séparer l'ingestion du travail de transformation.

```sql
CREATE FILE FORMAT IF NOT EXISTS FF_DATACO_CSV
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL')
    ENCODING = 'ISO88591';
```

`ENCODING = 'ISO88591'` correspond au jeu de caractères Latin-1 du fichier source DataCo et est reconnu tel quel par Snowflake.

À partir de la donnée brute, dbt crée plusieurs modèles Bronze :

```text
RAW_DATACO
    │
    ├── bronze_client
    ├── bronze_produit
    ├── bronze_departement
    ├── bronze_localisation
    ├── bronze_livraison
    └── bronze_commande
```

Cette première séparation rend le modèle plus lisible sans appliquer de transformation métier.

---

## 4. Silver — nettoyage et typage

La couche Silver transforme les données brutes en données exploitables.

Les principales opérations sont :

- conversion des identifiants en numériques ;
- conversion des dates ;
- conversion des montants en `DECIMAL` ;
- suppression des espaces inutiles avec `TRIM()` ;
- filtrage des identifiants invalides ;
- suppression des doublons lorsque nécessaire ;
- conservation des noms de colonnes source pour assurer la traçabilité.

### Exemple — typage des commandes

```sql
SELECT
    TRY_TO_NUMBER("Order Id") AS "Order Id",
    TRY_TO_NUMBER("Customer Id") AS "Customer Id",
    TRY_TO_NUMBER("Product Card Id") AS "Product Card Id",

    TRY_TO_TIMESTAMP(
        "order date (DateOrders)",
        'MM/DD/YYYY HH24:MI'
    ) AS "order date (DateOrders)",

    TRY_TO_DECIMAL("Sales", 18, 2) AS "Sales",

    TRY_TO_DECIMAL(
        "Order Item Discount Rate",
        10, 4
    ) AS "Order Item Discount Rate"

FROM {{ ref('bronze_commande') }}

WHERE TRY_TO_NUMBER("Order Id") IS NOT NULL
```

L'utilisation de `TRY_TO_*` permet de convertir les données sans faire échouer l'ensemble de la transformation sur une valeur mal formée.

---

## 5. Gold — modèles orientés métier

La couche Gold expose des tables directement utilisables pour l'analyse.

Trois modèles principaux ont été construits :

### `ventes`

Agrégation des ventes par date, produit, département et marché.

```sql
SELECT
    CAST(c."order date (DateOrders)" AS DATE)
        AS "order date (DateOrders)",
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name",
    c."Market",
    SUM(c."Order Item Quantity") AS "Order Item Quantity",
    ROUND(SUM(c."Sales"), 2) AS "Sales",
    ROUND(SUM(c."Order Item Discount"), 2) AS "Order Item Discount",
    COUNT(DISTINCT c."Order Id") AS "Nombre de commandes"
FROM {{ ref('silver_commande') }} c
LEFT JOIN {{ ref('silver_produit') }} p
    ON c."Product Card Id" = p."Product Card Id"
LEFT JOIN {{ ref('silver_departement') }} d
    ON c."Department Id" = d."Department Id"
GROUP BY
    CAST(c."order date (DateOrders)" AS DATE),
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name",
    c."Market"
```

### `performance_livraison`

Suivi des retards et de l'écart entre délai réel et délai prévu.

```sql
SELECT
    CAST("order date (DateOrders)" AS DATE)
        AS "order date (DateOrders)",
    "Shipping Mode",
    "Order Region",
    "Order Country",
    "Market",
    COUNT(DISTINCT "Order Id") AS "Nombre de commandes",
    COUNT(DISTINCT CASE
        WHEN "Days for shipping (real)"
           > "Days for shipment (scheduled)"
        THEN "Order Id"
    END) AS "Nombre de commandes en retard",
    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN "Days for shipping (real)"
               > "Days for shipment (scheduled)"
            THEN "Order Id"
        END)
        / NULLIF(COUNT(DISTINCT "Order Id"), 0),
        2
    ) AS "Taux de retard",
    ROUND(AVG("Days for shipping (real)"), 2)
        AS "Délai moyen réel",
    ROUND(AVG("Days for shipment (scheduled)"), 2)
        AS "Délai moyen prévu"
FROM {{ ref('silver_commande') }}
GROUP BY
    CAST("order date (DateOrders)" AS DATE),
    "Shipping Mode",
    "Order Region",
    "Order Country",
    "Market"
```

Résultats obtenus sur le périmètre du projet :

- **65 752 commandes**
- **37 698 commandes en retard**
- **57,33 % de taux de retard**
- **3,22 jours de délai réel moyen**
- **2,46 jours de délai prévu moyen**

### `performance_produit`

```sql
SELECT
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name",
    SUM(c."Order Item Quantity") AS "Quantité vendue",
    ROUND(SUM(c."Sales"), 2) AS "Chiffre d'affaires",
    ROUND(SUM(c."Order Item Discount"), 2) AS "Remises",
    ROUND(SUM(c."Order Profit Per Order"), 2) AS "Profit",
    COUNT(DISTINCT c."Order Id") AS "Nombre de commandes"
FROM {{ ref('silver_commande') }} c
LEFT JOIN {{ ref('silver_produit') }} p
    ON c."Product Card Id" = p."Product Card Id"
LEFT JOIN {{ ref('silver_departement') }} d
    ON c."Department Id" = d."Department Id"
GROUP BY
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name"
```

---

## 6. dbt — transformation & dépendances

dbt gère les transformations SQL, les dépendances et les tests, développés et exécutés directement dans **dbt Cloud**.

```sql
FROM {{ ref('silver_commande') }}
```

`ref()` permet à dbt de construire automatiquement le graphe de dépendances.

Le flux est :

```text
RAW_DATACO
     │
     ▼
BRONZE
     │
     ▼
SILVER
     │
     ▼
GOLD
```

Configuration des schémas :

```yaml
models:
  dbt_Logistic:
    BRONZE:
      +schema: BRONZE
      +materialized: table

    SILVER:
      +schema: SILVER
      +materialized: table

    GOLD:
      +schema: GOLD
      +materialized: table
```

### sources.yml

```yaml
version: 2

sources:
  - name: logistic_bronze
    database: LOGISTIC_DWH
    schema: BRONZE
    tables:
      - name: RAW_DATACO
```

La source dbt permet de distinguer la donnée brute externe au projet des modèles construits par dbt.

---

## 7. Data Quality & controls.yml

La qualité des données est contrôlée directement dans dbt avec :

- `not_null` ;
- `unique` ;
- relations entre tables ;
- valeurs positives ou non négatives ;
- taux compris entre 0 et 1 ;
- pourcentages compris entre 0 et 100 ;
- latitude / longitude valides ;
- cohérence des identifiants.

Le fichier `controls.yml` centralise les règles de qualité déclarées sur les modèles Silver et Gold. Il regroupe notamment les contrôles de clés obligatoires, d'unicité, de relations entre modèles et de domaines de valeurs.

### Exemple — relation

```yaml
- name: "Customer Id"
  quote: true
  tests:
    - not_null
    - relationships:
        to: ref('silver_client')
        field: '"Customer Id"'
```

### Exemple — test métier

```sql
{% test valid_discount_rate(model, column_name) %}

SELECT *
FROM {{ model }}

WHERE {{ column_name }} IS NULL
   OR {{ column_name }} < 0
   OR {{ column_name }} > 1

{% endtest %}
```

Le contrôle accepte donc une remise de `0` et vérifie que le taux reste compris entre `0` et `1`.

### Résultat

```text
15 modèles
70 tests
1 source

70 PASS
0 WARN
0 ERROR
0 SKIP
```

---

## 8. Contrôles SQL

### Vérification du volume

```sql
SELECT COUNT(*) AS "Nombre de lignes"
FROM LOGISTIC_DWH.BRONZE.RAW_DATACO;
```

### Vérification des commandes

```sql
SELECT
    COUNT(*) AS "Nombre de lignes",
    COUNT("Order Id") AS "Order Id renseignés",
    COUNT(DISTINCT "Order Id") AS "Commandes distinctes"
FROM LOGISTIC_DWH.SILVER.commande;
```

### Vérification des retards

```sql
SELECT
    "Shipping Mode",
    COUNT(DISTINCT "Order Id") AS "Nombre de commandes",
    COUNT(DISTINCT CASE
        WHEN "Days for shipping (real)"
           > "Days for shipment (scheduled)"
        THEN "Order Id"
    END) AS "Nombre de commandes en retard"
FROM LOGISTIC_DWH.SILVER.commande
GROUP BY "Shipping Mode"
ORDER BY "Nombre de commandes en retard" DESC;
```

### Analyse des ventes par marché

```sql
SELECT
    "Market",
    ROUND(SUM("Sales"), 2) AS "Chiffre d'affaires",
    COUNT(DISTINCT "Order Id") AS "Nombre de commandes"
FROM LOGISTIC_DWH.SILVER.commande
GROUP BY "Market"
ORDER BY "Chiffre d'affaires" DESC;
```

---

## 9. Structure du repository

```text
Logistics-Data-Platform/
│
├── README.md
│
├── aws-s3/
│   ├── Connexion AWS S3 - Snowflake...
│   └── database_aws.png
│
├── snowflake/
│   ├── 01_snowflake_setup.sql
│   ├── 02_bronze_ingestion.sql
│   └── 03_bronze_raw_dataco.sql
│
├── dbt/
│   ├── dbt_project.yml
│   ├── sources.yml
│   ├── controls.yml
│   ├── macros/
│   └── models/
│       ├── BRONZE/
│       ├── SILVER/
│       └── GOLD/
│
└── screenshots/
    ├── run_dbt_project.png
    ├── database_aws.png
    ├── run_test_dbt_project.png
    └── snowflake_dwh.png
```

### Convention de nommage

Tous les dossiers techniques sont en minuscules, avec des tirets pour séparer les mots (`kebab-case`) : `aws-s3/`, `snowflake/`, `dbt/`, `screenshots/`.

---

## 10. Lancer le projet

Ce projet a été entièrement développé et exécuté dans le cloud, sans environnement local :

- **Snowflake** héberge le Data Warehouse (bases, schémas, stage, storage integration) ;
- **dbt Cloud** héberge le projet dbt : connexion à Snowflake, développement des modèles, exécution des `dbt run` / `dbt test` / `dbt build` et consultation des logs se font directement depuis l'interface dbt Cloud ;
- le code (modèles, macros, fichiers YAML) est ensuite **publié manuellement sur GitHub** depuis dbt Cloud, sans utilisation de la ligne de commande ni de dbt Core en local.

Pour reproduire ce projet :

1. Créer un compte Snowflake et exécuter les scripts du dossier `snowflake/` (création du warehouse, de la base, du stage et de la storage integration S3) ;
2. Créer un projet dans dbt Cloud et le connecter à l'environnement Snowflake créé à l'étape précédente ;
3. Importer les fichiers du dossier `dbt/` dans le projet dbt Cloud ;
4. Lancer les commandes `dbt run` et `dbt test` (ou `dbt build`) depuis l'interface dbt Cloud.

---

## 11. Évolutions possibles

### Data Engineering

- automatisation du chargement des nouvelles données S3 ;
- orchestration du pipeline ;
- monitoring des traitements ;
- suivi des coûts Snowflake ;
- ajout de contrôles de qualité supplémentaires.

### Data Analytics / BI

Une couche analytique peut être ajoutée au-dessus des modèles Gold, notamment avec Power BI.

Les modèles `ventes`, `performance_livraison` et `performance_produit` pourraient alimenter un rapport orienté pilotage logistique :

- chiffre d'affaires ;
- performances produits ;
- suivi des retards ;
- analyse par marché ;
- délais de livraison.

Cette évolution permet de conserver une orientation Data Engineering / Analytics Engineering tout en valorisant les compétences Data Analyst / BI.

---

## 12. Ce que ce projet démontre

Ce projet met principalement en pratique :

- ingestion de données depuis **AWS S3** ;
- connexion sécurisée entre AWS et Snowflake ;
- organisation d'un Data Warehouse en couches Bronze / Silver / Gold ;
- transformation ELT avec dbt (via dbt Cloud) ;
- typage et nettoyage de données avec SQL ;
- modélisation orientée métier ;
- gestion des dépendances avec `ref()` ;
- tests de qualité et contrôles de cohérence ;
- documentation technique.

---

## Auteur

**Ahmed Zouaghi**

Projet personnel orienté **Data Engineering / Analytics Engineering**

Technologies principales : **AWS S3 · Snowflake · SQL · dbt Cloud · GitHub**
