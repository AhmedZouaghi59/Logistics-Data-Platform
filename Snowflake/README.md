# dbt — Logistics Data Platform

## 📊 Présentation

Ce dossier contient le projet **dbt** utilisé pour transformer, structurer et contrôler les données de la plateforme Logistics Data Platform.

dbt est utilisé au-dessus de **Snowflake** pour organiser les transformations SQL selon une architecture **Bronze / Silver / Gold**.

L'objectif est de partir de la table source `RAW_DATACO`, puis de construire progressivement des données nettoyées et des modèles orientés métier.

---

## 🎯 Objectifs

Le projet dbt permet de :

- structurer les données sources dans différentes couches ;
- nettoyer et typer les données avec SQL ;
- gérer les dépendances entre les modèles ;
- construire des modèles orientés analyse ;
- mettre en place des tests de qualité ;
- versionner les transformations avec Git ;
- rendre le pipeline plus clair et maintenable.

---

## 🛠️ Technologies

- **dbt Core / dbt** — transformation et modélisation
- **Snowflake** — Data Warehouse
- **SQL** — transformations
- **Git / GitHub** — versionnement

Versions utilisées sur le projet :

```text
dbt : 1.9.4
dbt-snowflake : 1.9.2
```

---

## 🧱 Architecture du projet

Le projet suit une architecture **Medallion** en trois couches :

```text
                                                    RAW_DATACO
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │   BRONZE    │
                                                  │ Structuration│
                                                  └──────┬──────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │   SILVER    │
                                                  │ Nettoyage   │
                                                  │ & typage    │
                                                  └──────┬──────┘
                                                         │
                                                         ▼
                                                  ┌─────────────┐
                                                  │    GOLD     │
                                                  │ Modèles     │
                                                  │ métier      │
                                                  └─────────────┘
```

Chaque couche correspond à une étape différente du traitement des données.

---

## 📁 Structure du projet

```text
                                        DBT/
                                        │
                                        ├── dbt_project.yml
                                        ├── profiles.yml
                                        ├── controls.yml
                                        ├── sources.yml
                                        │
                                        ├── macros/
                                        │   └── generate_schema_name.sql
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
                                            │   ├── silver_commande.sql
                                            │   └── controls.yml
                                            │
                                            └── GOLD/
                                                ├── gold_ventes.sql
                                                ├── gold_performance_livraison.sql
                                                ├── gold_performance_produit.sql
                                                └── controls.yml
```

---

## 📥 Source des données

La source Snowflake utilisée par dbt est la table :

```text
LOGISTIC_DWH.BRONZE.RAW_DATACO
```

Elle est déclarée dans `sources.yml` :

```yaml
version: 2

sources:
  - name: logistic_bronze
    database: LOGISTIC_DWH
    schema: BRONZE
    tables:
      - name: RAW_DATACO
```

Les modèles Bronze utilisent ensuite `source()` pour accéder aux données :

```sql
FROM {{ source('logistic_bronze', 'RAW_DATACO') }}
```

---

## 🥉 Couche Bronze

La couche Bronze permet de structurer les données issues de `RAW_DATACO` tout en restant proche de la source.

Les six modèles sont :

```text
bronze_client
bronze_produit
bronze_departement
bronze_localisation
bronze_livraison
bronze_commande
```

Les modèles Bronze utilisent principalement des `SELECT` sur la source, sans appliquer de nettoyage métier.

L'objectif est de conserver une première organisation logique des données avant leur transformation dans Silver.

---

## 🥈 Couche Silver

La couche Silver correspond au nettoyage et au typage des données.

Les modèles sont :

```text
silver_client
silver_produit
silver_departement
silver_localisation
silver_livraison
silver_commande
```

### Principales transformations

#### Nettoyage des textes

```sql
TRIM("Customer Email")
```

#### Conversion des identifiants

```sql
TRY_TO_NUMBER("Customer Id")
```

#### Conversion des montants

```sql
TRY_TO_DECIMAL("Sales",18,2)
```

#### Conversion des dates

```sql
TRY_TO_TIMESTAMP("order date (DateOrders)", 'MM/DD/YYYY HH24:MI')
```

#### Déduplication

Certaines tables de référence utilisent `SELECT DISTINCT` afin de conserver un ensemble de valeurs uniques.

La couche Silver permet ainsi de disposer de données plus propres et correctement typées avant leur utilisation dans les modèles Gold.

---

## 🥇 Couche Gold

La couche Gold regroupe les modèles orientés métier.

Trois modèles ont été développés.

### `gold_ventes`

Modèle permettant d'analyser les ventes par :

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

### `gold_performance_livraison`

Modèle consacré à l'analyse des performances de livraison.

Il contient notamment :

- nombre de commandes ;
- nombre de commandes en retard ;
- taux de retard ;
- délai moyen réel ;
- délai moyen prévu ;
- écart moyen entre délai réel et délai prévu.

La règle utilisée pour identifier un retard est :

```text
Days for shipping (real)
>
Days for shipment (scheduled)
```

### `gold_performance_produit`

Modèle permettant d'analyser la performance des produits à travers :

- quantité vendue ;
- chiffre d'affaires ;
- remises ;
- profit ;
- nombre de commandes.

---

## 🔗 Gestion des dépendances

Les dépendances entre les modèles sont gérées avec `ref()`.

Par exemple :

```sql
FROM {{ ref('silver_commande') }}
```

Cela permet à dbt de comprendre qu'un modèle Gold dépend d'un modèle Silver et de construire automatiquement les modèles dans le bon ordre.

Le graphe logique du projet peut ainsi être représenté comme suit :

```text
                                          RAW_DATACO
                                              │
                                              ▼
                                           BRONZE
                                              │
                                              ▼
                                           SILVER
                                              │
                                              ├──────────────┐
                                              │              │
                                              ▼              ▼
                                           GOLD ventes   GOLD performance
                                                         livraison / produit
```

---

## ⚙️ Configuration dbt

Le fichier `dbt_project.yml` configure notamment les schémas et la matérialisation des modèles.

Les modèles sont organisés directement dans les schémas Snowflake :

```text
BRONZE → table
SILVER → table
GOLD   → table
```

Une macro `generate_schema_name.sql` permet de conserver directement les noms de schémas `BRONZE`, `SILVER` et `GOLD` dans Snowflake.

---

## 🧪 Tests de qualité

Des tests dbt ont été ajoutés sur les colonnes importantes du projet.

Les contrôles portent notamment sur :

- `not_null` pour vérifier la présence de valeurs ;
- `unique` pour contrôler l'unicité de certains identifiants.

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

Le projet a été exécuté avec :

```text
15 modèles
24 tests
1 source
```

Dernier `dbt run` :

```text
15 PASS
0 WARN
0 ERROR
```

Dernier `dbt test` :

```text
24 PASS
0 WARN
0 ERROR
```

Orientation : **Data Engineering / Analytics Engineering**
