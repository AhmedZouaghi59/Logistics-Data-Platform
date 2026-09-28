# 🔍 DBT — Logistics Data Platform

## 📊 Présentation

Ce dossier contient la partie **dbt** du projet Logistics Data Platform.

dbt est utilisé pour transformer les données chargées dans Snowflake, organiser les modèles selon une architecture **Bronze / Silver / Gold** et mettre en place des contrôles de qualité sur les données.

L'objectif est de conserver une logique de transformation claire, versionnée et facilement maintenable.

---

## 🧱 Architecture dbt

Le projet suit la structure suivante :

```text
DBT/
│
├── dbt_project.yml
├── profiles.yml
├── controls.yml
├── sources.yml
│
├── macros/
│   ├── generate_schema_name.sql
│   └── data_quality_tests.sql
│
└── models/
    │
    ├── BRONZE/
    │   ├── bronze_client.sql
    │   ├── bronze_produit.sql
    │   ├── bronze_departement.sql
    │   ├── bronze_localisation.sql
    │   ├── bronze_livraison.sql
    │   └── bronze_commande.sql
    │
    ├── SILVER/
    │   ├── silver_client.sql
    │   ├── silver_produit.sql
    │   ├── silver_departement.sql
    │   ├── silver_localisation.sql
    │   ├── silver_livraison.sql
    │   └── silver_commande.sql
    │
    └── GOLD/
        ├── gold_ventes.sql
        ├── gold_performance_livraison.sql
        └── gold_performance_produit.sql
```

---

## 🔄 Flux de transformation

```text
Snowflake
    │
    ▼
RAW_DATACO
    │
    ▼
┌───────────────┐
│    BRONZE     │
│ Structuration │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│    SILVER     │
│ Nettoyage     │
│ Typage        │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     GOLD      │
│ Modèles métier│
└───────────────┘
```

---

## 🥉 Bronze

Les modèles Bronze récupèrent les données depuis la source Snowflake `RAW_DATACO`.

La source est déclarée dans `sources.yml` :

```yaml
version: 2

sources:
  - name: logistic_bronze
    database: LOGISTIC_DWH
    schema: BRONZE
    tables:
      - name: RAW_DATACO
```

Les modèles Bronze utilisent ensuite `source()` :

```sql
SELECT
    "Customer Id",
    "Customer Email",
    "Customer Fname",
    "Customer Lname",
    "Customer Segment",
    "Customer City",
    "Customer State",
    "Customer Country"
FROM {{ source('logistic_bronze', 'RAW_DATACO') }}
```

Cette couche reste volontairement proche de la source afin de conserver une première représentation structurée des données.

---

## 🥈 Silver

La couche Silver correspond au nettoyage et au typage des données.

Quelques transformations réalisées :

```sql
SELECT
    TRY_TO_NUMBER("Customer Id") AS "Customer Id",
    TRIM("Customer Email") AS "Customer Email",
    TRIM("Customer Fname") AS "Customer Fname",
    TRIM("Customer Lname") AS "Customer Lname",
    TRIM("Customer City") AS "Customer City"
FROM {{ ref('bronze_client') }}
```

### Conversion des données numériques

Les identifiants sont convertis avec `TRY_TO_NUMBER()` :

```sql
TRY_TO_NUMBER("Product Card Id") AS "Product Card Id"
```

Les montants sont convertis avec `TRY_TO_DECIMAL()` :

```sql
TRY_TO_DECIMAL("Sales", 18, 2) AS "Sales"
```

### Conversion des dates

Les dates du dataset sont converties avec `TRY_TO_TIMESTAMP()` :

```sql
TRY_TO_TIMESTAMP(
    "order date (DateOrders)",
    'MM/DD/YYYY HH24:MI'
) AS "order date (DateOrders)"
```

### Gestion des lignes invalides

Le modèle `silver_commande` conserve uniquement les commandes ayant un identifiant exploitable :

```sql
WHERE TRY_TO_NUMBER("Order Id") IS NOT NULL
```

---

## 🥇 Gold

La couche Gold contient les modèles orientés métier.

### `gold_ventes`

Le modèle agrège les ventes par date, produit, département et marché :

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
    SUM(c."Order Item Quantity")
        AS "Order Item Quantity",
    ROUND(SUM(c."Sales"), 2)
        AS "Sales",
    ROUND(SUM(c."Order Item Discount"), 2)
        AS "Order Item Discount",
    COUNT(DISTINCT c."Order Id")
        AS "Nombre de commandes"
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

Ce modèle permet notamment d'obtenir le **chiffre d'affaires**, les **quantités vendues**, les **remises** et le **nombre de commandes**.

---

## 🚚 Performance des livraisons

Le modèle `gold_performance_livraison` permet de mesurer les performances logistiques.

Une commande est considérée comme en retard lorsque le délai réel dépasse le délai prévu :

```sql
CASE
    WHEN "Days for shipping (real)"
       > "Days for shipment (scheduled)"
    THEN "Order Id"
END
```

Le taux de retard est ensuite calculé directement dans le modèle :

```sql
ROUND(
    100.0 *
    COUNT(DISTINCT CASE
        WHEN "Days for shipping (real)"
           > "Days for shipment (scheduled)"
        THEN "Order Id"
    END)
    / NULLIF(COUNT(DISTINCT "Order Id"), 0),
    2
) AS "Taux de retard"
```

Le modèle fournit également :

- le nombre de commandes ;
- le nombre de commandes en retard ;
- le taux de retard ;
- le délai moyen réel ;
- le délai moyen prévu ;
- l'écart moyen entre les deux.

---

## 📦 Performance produit

Le modèle `gold_performance_produit` regroupe les indicateurs par produit :

```sql
SELECT
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name",
    SUM(c."Order Item Quantity")
        AS "Quantité vendue",
    ROUND(SUM(c."Sales"), 2)
        AS "Chiffre d'affaires",
    ROUND(SUM(c."Order Item Discount"), 2)
        AS "Remises",
    ROUND(SUM(c."Order Profit Per Order"), 2)
        AS "Profit",
    COUNT(DISTINCT c."Order Id")
        AS "Nombre de commandes"
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

## 🔗 Dépendances entre les modèles

dbt permet de gérer les dépendances entre les différentes couches grâce à `ref()`.

```text
bronze_client
      │
      ▼
silver_client

bronze_produit
      │
      ▼
silver_produit
      │
      └──────────────┐
                     ▼
              silver_commande
                     │
          ┌──────────┼──────────┐
          ▼          ▼          ▼
      gold_ventes  performance  performance
                   livraison     produit
```

Les relations entre les données sont également contrôlées avec les tests `relationships`.

Exemple :

```yaml
- name: "Customer Id"
  quote: true
  tests:
    - not_null
    - relationships:
        to: ref('silver_client')
        field: '"Customer Id"'
```

Cela vérifie que chaque `Customer Id` présent dans les commandes existe bien dans la table `silver_client`.

---

## 🧪 Contrôles de qualité

Le projet contient actuellement :

```text
15 modèles
70 tests
1 source
```

Les contrôles couvrent plusieurs niveaux.

### Contrôles structurels

```yaml
tests:
  - not_null
  - unique
```

Ils permettent notamment de contrôler les identifiants clients, produits, départements et lignes de commande.

### Contrôles de relations

```yaml
relationships:
  to: ref('silver_produit')
  field: '"Product Card Id"'
```

Les principales relations contrôlées sont :

```text
silver_commande.Customer Id
        ↓
silver_client.Customer Id

silver_commande.Product Card Id
        ↓
silver_produit.Product Card Id

silver_commande.Department Id
        ↓
silver_departement.Department Id
```

### Contrôles métier personnalisés

Des tests personnalisés sont définis dans :

```text
macros/data_quality_tests.sql
```

Exemples :

```sql
{% test positive_value(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} IS NULL
   OR {{ column_name }} <= 0

{% endtest %}
```

Ce test est utilisé pour vérifier notamment que les ventes, quantités et prix restent strictement positifs.

Le taux de remise est contrôlé avec une règle comprise entre 0 et 1 :

```sql
{% test valid_discount_rate(model, column_name) %}

SELECT *
FROM {{ model }}
WHERE {{ column_name }} IS NULL
   OR {{ column_name }} < 0
   OR {{ column_name }} > 1

{% endtest %}
```

D'autres contrôles vérifient notamment :

- les valeurs positives ou nulles ;
- les taux compris entre 0 et 100 ;
- les latitudes entre -90 et 90 ;
- les longitudes entre -180 et 180 ;
- les valeurs autorisées de `Late_delivery_risk`.

---

## ✅ Résultats des tests

Le dernier `dbt test` a été exécuté avec succès :

```text
70 tests exécutés
70 PASS
0 WARN
0 ERROR
0 SKIP
```

Configuration utilisée :

```text
dbt        1.9.4
Snowflake  1.9.2
Threads    8
Target     dev
```

---

## ⚙️ Configuration du projet

Les modèles sont configurés dans `dbt_project.yml` selon les trois couches :

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

Une macro `generate_schema_name.sql` permet de conserver directement les schémas `BRONZE`, `SILVER` et `GOLD`.

---

## 🚀 Exécution

Depuis le dossier `DBT` :

```bash
dbt debug --target dev
```

Construire les modèles :

```bash
dbt run --target dev
```

Exécuter les contrôles :

```bash
dbt test --target dev
```

---

## 💡 Ce que cette partie dbt m'a permis de pratiquer

- transformations SQL avec dbt ;
- architecture Bronze / Silver / Gold ;
- modélisation de données ;
- gestion des dépendances avec `ref()` et `source()` ;
- tests de qualité standards ;
- tests métier personnalisés avec des macros ;
- contrôles d'intégrité référentielle ;
- agrégations et modèles analytiques ;
- organisation et versionnement d'un projet Data Engineering.

---

## 👤 Auteur

**Ahmed Zouaghi**

Master 2 SIAD — Business Intelligence  
Université de Lille

Orientation : **Data Engineering / Analytics Engineering**
