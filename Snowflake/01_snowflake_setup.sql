-- ============================================================
-- LOGISTICS DATA PLATFORM
-- Snowflake - Medallion Architecture
-- Bronze / Silver / Gold
-- ============================================================


-- ============================================================
-- 1. DATABASE
-- ============================================================

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS LOGISTIC_DWH;


-- ============================================================
-- 2. WAREHOUSE
-- ============================================================

-- Warehouse X-Small pour limiter la consommation de crédits
CREATE WAREHOUSE IF NOT EXISTS LOGISTIC_WH
WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;


-- ============================================================
-- 3. SCHEMAS - MEDALLION ARCHITECTURE
-- ============================================================

-- BRONZE
-- Données sources issues de S3
CREATE SCHEMA IF NOT EXISTS LOGISTIC_DWH.BRONZE;

-- SILVER
-- Données structurées, typées et fiabilisées
CREATE SCHEMA IF NOT EXISTS LOGISTIC_DWH.SILVER;

-- GOLD
-- Données préparées pour les usages métier
CREATE SCHEMA IF NOT EXISTS LOGISTIC_DWH.GOLD;


-- ============================================================
-- 4. ROLE
-- ============================================================

-- Rôle dédié à la plateforme Logistics
CREATE ROLE IF NOT EXISTS LOGISTIC_ADMIN;

-- Intégration dans la hiérarchie Snowflake
GRANT ROLE LOGISTIC_ADMIN TO ROLE SYSADMIN;


-- ============================================================
-- 5. DATABASE & WAREHOUSE ACCESS
-- ============================================================

GRANT USAGE
ON DATABASE LOGISTIC_DWH
TO ROLE LOGISTIC_ADMIN;

GRANT USAGE
ON WAREHOUSE LOGISTIC_WH
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 6. BRONZE
-- ============================================================

-- Accès au schéma Bronze
GRANT USAGE
ON SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

-- Création de la zone d'ingestion S3
GRANT CREATE STAGE
ON SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

-- Création des tables sources
GRANT CREATE TABLE
ON SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

-- Création éventuelle de vues techniques
GRANT CREATE VIEW
ON SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

-- Création des formats de fichiers
GRANT CREATE FILE FORMAT
ON SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 7. SILVER
-- ============================================================

-- Accès au schéma Silver
GRANT USAGE
ON SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;

-- dbt crée les modèles Silver
GRANT CREATE TABLE
ON SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;

GRANT CREATE VIEW
ON SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 8. GOLD
-- ============================================================

-- Accès au schéma Gold
GRANT USAGE
ON SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;

-- dbt crée les modèles Gold
GRANT CREATE TABLE
ON SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;

GRANT CREATE VIEW
ON SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 9. LECTURE DE LA BRONZE
-- ============================================================

-- Permet à dbt de lire les données sources
GRANT SELECT
ON ALL TABLES IN SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

-- Cas où des vues seraient utilisées dans Bronze
GRANT SELECT
ON ALL VIEWS IN SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE VIEWS IN SCHEMA LOGISTIC_DWH.BRONZE
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 10. LECTURE DE LA SILVER
-- ============================================================

-- La Gold consomme les modèles Silver
GRANT SELECT
ON ALL TABLES IN SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON ALL VIEWS IN SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE VIEWS IN SCHEMA LOGISTIC_DWH.SILVER
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 11. LECTURE DE LA GOLD
-- ============================================================

-- Lecture des modèles Gold pour les contrôles et la consommation
GRANT SELECT
ON ALL TABLES IN SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE TABLES IN SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON ALL VIEWS IN SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;

GRANT SELECT
ON FUTURE VIEWS IN SCHEMA LOGISTIC_DWH.GOLD
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 12. GESTION DES SCHÉMAS PAR DBT
-- ============================================================

-- dbt pourra créer les schémas nécessaires à partir du dbt_project.yml
GRANT CREATE SCHEMA
ON DATABASE LOGISTIC_DWH
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 13. UTILISATEUR
-- ============================================================

GRANT ROLE LOGISTIC_ADMIN
TO USER AHMEDZ59;