# 🚚 Logistics Data Platform — AWS S3, Snowflake & dbt

## 📊 Présentation

Ce projet consiste à construire une plateforme de données dédiée à l'analyse de données de **Supply Chain**.

L'objectif est de mettre en place une chaîne de traitement allant du stockage des données sources dans **AWS S3** jusqu'à la création de données structurées et orientées métier dans **Snowflake**, avec **dbt** pour gérer les transformations, la modélisation et les contrôles de qualité.

Le projet s'appuie sur le **DataCo Supply Chain Dataset**, contenant des informations sur les commandes, clients, produits, ventes et livraisons.

---

## 🎯 Objectifs

Le projet vise à :

- stocker les données sources dans AWS S3 ;
- connecter AWS S3 à Snowflake ;
- charger les données dans un Data Warehouse ;
- structurer les données selon une architecture **Bronze / Silver / Gold** ;
- nettoyer et typer les données avec dbt ;
- construire des modèles orientés métier ;
- mettre en place des contrôles de qualité ;
- versionner et documenter le projet avec GitHub.

---

## 🛠️ Technologies

| Technologie | Utilisation |
|---|---|
| **AWS S3** | Stockage des données sources |
| **Snowflake** | Data Warehouse et ingestion |
| **SQL** | Chargement et transformations |
| **dbt** | Transformation, modélisation et tests |
| **Git / GitHub** | Versionnement et documentation |

---

## 🧱 Architecture & Modélisation

Le projet repose sur une architecture de type **Medallion**, organisée en trois couches :

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
                                                                        │   Données brutes│
                                                                        └────────┬────────┘
                                                                                 │
                                                                                 ▼
                                                                        ┌─────────────────┐
                                                                        │     SILVER      │
                                                                        │ Nettoyage &     │
                                                                        │      typage     │
                                                                        └────────┬────────┘
                                                                                 │
                                                                                 ▼
                                                                        ┌─────────────────┐
                                                                        │      GOLD       │
                                                                        │ Modèles métier  │
                                                                        └─────────────────┘
```

Cette organisation permet de séparer les différentes étapes du traitement :

- **Bronze** : ingestion et structuration initiale des données sources ;
- **Silver** : nettoyage, standardisation et typage des données ;
- **Gold** : préparation des données pour l'analyse et les besoins métier.

---

## ☁️ AWS S3

AWS S3 constitue le point d'entrée du pipeline.

Le fichier source est stocké dans un bucket privé et organisé de manière à séparer les données brutes :

```text
logistics-data-platform-ahmed/
└── raw/
    └── dataco/
        └── DataCoSupplyChainDataset.csv
```

La connexion avec Snowflake est réalisée à l'aide d'une **IAM Role** et d'une **Storage Integration**.

La configuration AWS utilisée pour le projet est disponible ici :

**[Voir la configuration AWS S3 →](AWS%20S3/)**

> Les informations sensibles telles que les clés AWS, mots de passe ou identifiants temporaires ne sont pas stockées dans le repository.

---

## 🗄️ Snowflake

Snowflake constitue le **Data Warehouse** du projet.

La base de données est organisée en trois schémas correspondant aux différentes couches :

```text
LOGISTIC_DWH
│
├── BRONZE
├── SILVER
└── GOLD
```

Un warehouse dédié est utilisé :

```text
LOGISTIC_WH
```

### ⚙️ Ingestion

La connexion entre AWS S3 et Snowflake repose sur :

- une **IAM Role AWS** ;
- une **Storage Integration Snowflake** ;
- un **External Stage** ;
- un **File Format** adapté au fichier source ;
- `COPY INTO` pour charger les données.

Le fichier source est d'abord chargé dans :

```text
BRONZE.RAW_DATACO
```

Cette table conserve les données proches de la source avant leur transformation avec dbt.

La configuration Snowflake complète est disponible ici :

**[Voir les scripts Snowflake →](Snowflake/)**

---

## 🥉 Bronze

La couche **Bronze** correspond à la première étape de structuration des données.

La table source `RAW_DATACO` est répartie en plusieurs modèles afin de faciliter les traitements suivants :

```text
BRONZE
│
├── client
├── produit
├── departement
├── localisation
├── livraison
└── commande
```

Cette couche reste volontairement proche de la source et conserve les noms de colonnes du dataset.

---

## 🥈 Silver

La couche **Silver** est destinée au nettoyage et au typage des données.

Les modèles sont :

```text
SILVER
│
├── client
├── produit
├── departement
├── localisation
├── livraison
└── commande
```

Les principales transformations réalisées avec dbt sont :

- nettoyage des champs texte avec `TRIM()` ;
- conversion des identifiants avec `TRY_TO_NUMBER()` ;
- conversion des montants avec `TRY_TO_DECIMAL()` ;
- conversion des dates avec `TRY_TO_TIMESTAMP()` ;
- déduplication de certaines tables de référence.

L'objectif est d'obtenir des données plus propres et correctement typées avant la construction des modèles métier.

---

## 🥇 Gold

La couche **Gold** contient les modèles préparés pour l'analyse.

Trois modèles principaux ont été développés :

### `ventes`

Permet d'analyser les ventes selon :

- la date ;
- le produit ;
- la catégorie ;
- le département ;
- le marché.

Principaux indicateurs :

- quantité vendue ;
- chiffre d'affaires ;
- remises ;
- nombre de commandes.

### `performance_livraison`

Permet d'analyser la performance logistique à travers :

- nombre de commandes ;
- nombre de commandes en retard ;
- taux de retard ;
- délai réel moyen ;
- délai prévu moyen ;
- écart moyen entre les deux.

Une commande est considérée comme en retard lorsque :

```text
Days for shipping (real)
>
Days for shipment (scheduled)
```

### `performance_produit`

Permet d'analyser la performance des produits à travers :

- quantité vendue ;
- chiffre d'affaires ;
- remises ;
- profit ;
- nombre de commandes.

---

## 🔍 dbt

dbt est utilisé pour gérer les transformations SQL, les dépendances entre modèles et les contrôles de qualité.

Le projet dbt contient actuellement :

```text
15 modèles
24 tests
1 source
```

Les dépendances entre les modèles sont gérées avec `ref()`.

Exemple :

```sql
FROM {{ ref('silver_commande') }}
```

La source Snowflake est déclarée avec `source()` :

```sql
FROM {{ source('logistic_bronze', 'RAW_DATACO') }}
```

Cela permet à dbt de comprendre les dépendances et d'exécuter les modèles dans le bon ordre.

La documentation détaillée du projet dbt est disponible ici :

**[Voir le projet dbt →](DBT/)**

---

## 🧪 Qualité des données

Des tests dbt sont utilisés pour contrôler les données importantes du modèle.

Les contrôles portent notamment sur :

- les valeurs nulles ;
- l'unicité des identifiants.

Exemples de champs contrôlés :

```text
Customer Id
Product Card Id
Department Id
Order Id
Order Item Id
order date (DateOrders)
Shipping Mode
```

### Résultats

Dernier `dbt run` :

```text
15 modèles exécutés
15 PASS
0 WARN
0 ERROR
```

Dernier `dbt test` :

```text
24 tests exécutés
24 PASS
0 WARN
0 ERROR
```

---

## 📂 Données

### Source

**DataCo Supply Chain Dataset**

Le dataset contient notamment des informations relatives aux :

- commandes ;
- clients ;
- produits ;
- ventes ;
- remises ;
- bénéfices ;
- livraisons ;
- localisations.

La source utilisée dans le projet contient :

```text
180 519 lignes
53 colonnes
```

Le fichier est stocké dans AWS S3 avant d'être chargé dans Snowflake.

---

## 📈 Modèles analytiques

Les données finales sont organisées autour de trois principaux axes :

```text
                                                                             GOLD
                                                                               │
                                                              ┌────────────────┼────────────────┐
                                                              │                │                │
                                                              ▼                ▼                ▼
                                                            Ventes        Performance      Performance
                                                                          livraison         produit
                                                              │                │                │
                                                              ▼                ▼                ▼
                                                         Performance       Analyse des      Analyse des
                                                         commerciale        délais           produits
```

Ces modèles permettent de disposer de données déjà structurées pour une utilisation analytique en aval.

---

## 📁 Structure du repository

Le repository reste volontairement simple afin de séparer les différents composants du projet :

```text
                                                                  logistics-platform-data/
                                                                  │
                                                                  ├── README.md
                                                                  │
                                                                  ├── AWS S3/
                                                                  │   ├── Connexion AWS S3 - Snowflake...
                                                                  │   └── database_aws.png
                                                                  │
                                                                  ├── DBT/
                                                                  │   ├── dbt_project.yml
                                                                  │   ├── profiles.yml
                                                                  │   ├── controls.yml
                                                                  │   ├── sources.yml
                                                                  │   │
                                                                  │   ├── macros/
                                                                  │   │   └── generate_schema_name.sql
                                                                  │   │
                                                                  │   └── models/
                                                                  │       ├── BRONZE/
                                                                  │       ├── SILVER/
                                                                  │       └── GOLD/
                                                                  │
                                                                  ├── Screenshots/
                                                                  │   ├── Run dbt project.png
                                                                  │   ├── database_aws.png
                                                                  │   ├── run test dbt project.png
                                                                  │   └── snowflake_dwh.png
                                                                  │
                                                                  └── Snowflake/
                                                                      ├── 01_snowflake_setup.sql
                                                                      ├── 02_bronze_ingestion.sql
                                                                      └── 03_bronze_raw_dataco.sql
```

Cette organisation permet de retrouver rapidement :

- la configuration AWS ;
- la configuration Snowflake ;
- la logique de transformation dbt ;
- les modèles Bronze, Silver et Gold ;
- les contrôles de qualité.

---

## 📚 Documentation

Les différents éléments du projet sont accessibles directement depuis le repository :

- **[Configuration AWS S3](AWS%20S3/)** — configuration du stockage et des accès S3
- **[Configuration Snowflake](Snowflake/)** — création de l'environnement Snowflake et des schémas
- **[Documentation dbt](dbt_Logistic/README.md)** — structure, modèles, transformations et tests dbt

---

## 💡 Ce que ce projet m'a permis de pratiquer

Ce projet m'a permis de mettre en pratique plusieurs notions de Data Engineering :

- stockage de données dans AWS S3 ;
- connexion entre AWS S3 et Snowflake ;
- ingestion de données dans un Data Warehouse ;
- architecture Medallion / Bronze, Silver, Gold ;
- transformations SQL avec dbt ;
- modélisation de données ;
- tests de qualité des données ;
- documentation avec GitHub.

---

## 👤 Auteur

**Ahmed Zouaghi**

Master 2 SIAD — Business Intelligence  
Université de Lille

Orientation : **Data Engineering / Analytics Engineering**
