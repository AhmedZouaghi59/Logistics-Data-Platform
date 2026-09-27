-- ============================================================
-- 1. CONFIGURATION
-- ============================================================

USE ROLE LOGISTIC_ADMIN;

USE DATABASE LOGISTIC_DWH;
USE WAREHOUSE LOGISTIC_WH;
USE SCHEMA BRONZE;


-- ============================================================
-- 2. FILE FORMAT
-- ============================================================

-- Format du fichier source DataCo
-- L'en-tête est ignoré lors du chargement.
-- Les colonnes seront stockées en VARCHAR dans la Bronze.

CREATE FILE FORMAT IF NOT EXISTS FF_DATACO_CSV
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL = TRUE
    NULL_IF = ('', 'NULL')
    ENCODING = 'ISO88591';


-- ============================================================
-- 3. EXTERNAL STAGE
-- ============================================================

-- Stage pointant vers les données DataCo sur AWS S3

CREATE STAGE IF NOT EXISTS STAGE_DATACO
    URL = 's3://logistics-data-platform-ahmed/raw/dataco/'
    STORAGE_INTEGRATION = LOGISTIC_S3_INT
    FILE_FORMAT = FF_DATACO_CSV;


-- ============================================================
-- 4. VERIFICATION DES FICHIERS S3
-- ============================================================

LIST @STAGE_DATACO;


-- ============================================================
-- 5. VERIFICATION DE LA STRUCTURE DU FICHIER
-- ============================================================

-- Permet de vérifier les colonnes détectées dans le fichier source.
-- Les types retournés par INFER_SCHEMA ne sont PAS utilisés
-- pour la Bronze : la Bronze conservera toutes les colonnes en VARCHAR.

SELECT *
FROM TABLE(
    INFER_SCHEMA(
        LOCATION => '@STAGE_DATACO',
        FILE_FORMAT => 'FF_DATACO_CSV'
    )
)
ORDER BY ORDER_ID;


-- ============================================================
-- 6. VERIFICATION DE LA CONFIGURATION
-- ============================================================

-- Vérification du stage DataCo
DESC STAGE STAGE_DATACO;

-- Vérification du format CSV
DESC FILE FORMAT FF_DATACO_CSV;