# 🚚 Logistics Data Platform — AWS S3 & Snowflake & dbt

## 📊 Présentation

Ce projet consiste à construire une petite plateforme de données dédiée à l'analyse de données de supply chain.

L'objectif est de mettre en place une chaîne de traitement allant du stockage des données brutes dans **AWS S3** jusqu'à la création de données structurées et orientées métier dans **Snowflake**, avec **dbt** pour gérer les transformations et les contrôles de qualité.

Le projet s'appuie sur le **DataCo Supply Chain Dataset**, contenant des informations sur les commandes, clients, produits, ventes et livraisons.

---

## 🎯 Objectifs

Le projet cherche notamment à :

- centraliser les données sources dans un environnement cloud ;
- charger les données dans Snowflake ;
- structurer les données selon une architecture **Bronze / Silver / Gold** ;
- nettoyer et typer les données avec dbt ;
- créer des modèles orientés métier ;
- mettre en place des contrôles de qualité ;
- conserver une organisation claire et facilement maintenable.

---

## 🛠️ Technologies

- **AWS S3** — stockage des données sources
- **Snowflake** — Data Warehouse
- **SQL** — ingestion et transformations
- **dbt** — transformation, modélisation et tests
- **Git / GitHub** — versionnement et documentation

---

## 🧱 Architecture & Modélisation

Le projet repose sur une architecture de type **Medallion**, organisée en trois couches :

```text
                                             DataCo CSV
                                                 ↓
                                              AWS S3
                                                 ↓
                                             Snowflake
                                                 ↓
                                             BRONZE
                                                 ↓
                                              SILVER
                                                 ↓
                                               GOLD

Cette organisation permet de séparer les différentes étapes du traitement : ingestion, nettoyage, typage et préparation des données pour l'analyse.

---

## 🗄️ Snowflake

Snowflake constitue le Data Warehouse du projet.

La base est organisée de la manière suivante :

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

### ⚙️ Mise en place

La connexion entre AWS S3 et Snowflake repose sur une **Storage Integration** associée à un rôle IAM AWS.

Le fichier source est ensuite accessible depuis Snowflake grâce à un **External Stage**.

Le chargement est réalisé dans la table :

```text
BRONZE.RAW_DATACO
```

à l'aide de `COPY INTO`.

Le projet contient également un **File Format** adapté au fichier source, notamment pour gérer son encodage.

La configuration complète de l'environnement Snowflake est disponible dans :

[`snowflake/setup.sql`](snowflake/setup.sql)

---

## 🥉 Bronze

La couche Bronze correspond aux données proches de la source.

Le fichier `RAW_DATACO` est réparti en plusieurs modèles afin de faciliter la suite du traitement :

```text
client
produit
departement
localisation
livraison
commande
```

Cette couche conserve les noms de colonnes issus du dataset afin de garder une correspondance avec la source.

---

## 🥈 Silver

La couche Silver est utilisée pour nettoyer et typer les données.

Les principales transformations réalisées avec dbt sont notamment :

- nettoyage des champs texte avec `TRIM()` ;
- conversion des identifiants avec `TRY_TO_NUMBER()` ;
- conversion des montants avec `TRY_TO_DECIMAL()` ;
- conversion des dates avec `TRY_TO_TIMESTAMP()` ;
- déduplication de certaines tables de référence.

Les modèles Silver sont :

```text
client
produit
departement
localisation
livraison
commande
```

Cette couche permet d'obtenir des données plus propres et adaptées aux transformations métier.

---

## 🥇 Gold

La couche Gold contient les modèles préparés pour l'analyse.

Trois modèles ont été développés :

### `ventes`

Ce modèle permet d'analyser les ventes selon différents axes :

- date ;
- produit ;
- catégorie ;
- département ;
- marché.

Les principaux indicateurs sont :

- quantité vendue ;
- chiffre d'affaires ;
- remises ;
- nombre de commandes.

### `performance_livraison`

Ce modèle permet d'étudier la performance des livraisons.

Il contient notamment :

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

Ce modèle permet d'analyser la performance des produits à travers :

- quantité vendue ;
- chiffre d'affaires ;
- remises ;
- profit ;
- nombre de commandes.

---

## 🔍 dbt

dbt est utilisé pour gérer les transformations SQL et les dépendances entre les différents modèles.

Le projet contient actuellement :

```text
15 modèles
24 tests
1 source
```

Les dépendances sont gérées avec `ref()`.

Exemple :

```sql
FROM {{ ref('silver_commande') }}
```

La source Snowflake est déclarée avec `source()` :

```sql
FROM {{ source('logistic_bronze', 'RAW_DATACO') }}
```

Cela permet à dbt de construire les modèles dans le bon ordre.

---

## 🧪 Qualité des données

Des tests dbt ont été ajoutés afin de contrôler la qualité de certaines données importantes.

Les tests portent notamment sur :

- les valeurs nulles ;
- l'unicité des identifiants.

Les principaux champs contrôlés sont notamment :

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

Le dernier `dbt run` :

```text
15 modèles exécutés
15 PASS
0 WARN
0 ERROR
```

Le dernier `dbt test` :

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
- localisation des commandes.

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
Ventes
   ↓
Performance commerciale

Livraisons
   ↓
Performance logistique

Produits
   ↓
Performance produit
```

Ces modèles permettent de disposer de données déjà structurées pour une utilisation analytique en aval.

---

## 📐 Documentation

Le repository contient également :

- [Configuration Snowflake](snowflake/setup.sql)
- [Projet dbt](dbt_Logistic/README.md)
- [Configuration AWS](aws/setup.sql)

---

## 🚀 Lancer le projet

Après avoir configuré Snowflake, AWS et dbt, se placer dans le dossier :

```bash
cd dbt_Logistic
```

Vérifier la configuration :

```bash
dbt debug --target dev
```

Construire les modèles :

```bash
dbt run --target dev
```

Lancer les tests :

```bash
dbt test --target dev
```

---

## 💡 Ce que ce projet m'a permis de pratiquer

Ce projet m'a permis de mettre en pratique plusieurs notions de Data Engineering :

- stockage de données dans AWS S3 ;
- connexion entre AWS et Snowflake ;
- ingestion de données dans un Data Warehouse ;
- architecture Bronze / Silver / Gold ;
- transformations SQL avec dbt ;
- modélisation de données ;
- tests de qualité ;
- gestion des dépendances avec dbt ;
- versionnement avec Git et GitHub.

J'ai volontairement gardé une architecture relativement simple afin de comprendre chaque étape du traitement et de pouvoir expliquer les choix techniques réalisés.

---

## 🔮 Évolutions possibles

Plusieurs améliorations pourraient être ajoutées par la suite :

- mise en place de chargements incrémentaux ;
- ajout de tests dbt supplémentaires ;
- contrôle de fraîcheur des sources ;
- automatisation de l'exécution du pipeline ;
- mise en place d'une CI avec GitHub Actions ;
- documentation dbt plus complète.

---

## 👤 Auteur

**Ahmed Zouaghi**

Master 2 SIAD — Business Intelligence  
Université de Lille

Orientation : **Data Engineering / Analytics Engineering**
