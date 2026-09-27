-- ============================================================
-- 1. STORAGE INTEGRATION
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- Permet à Snowflake d'accéder au bucket S3 via un rôle IAM
CREATE STORAGE INTEGRATION IF NOT EXISTS LOGISTIC_S3_INT
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = 'S3'
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::820567439282:role/LOGISTIC_S3_ROLE'
    ENABLED = TRUE
    STORAGE_ALLOWED_LOCATIONS = ('s3://logistics-data-platform-ahmed/raw/');


-- Vérification de la configuration générée par Snowflake
DESC INTEGRATION LOGISTIC_S3_INT;


-- ============================================================
-- 2. STORAGE INTEGRATION ACCESS
-- ============================================================

-- Autorise le rôle du projet à utiliser l'intégration S3
GRANT USAGE
ON INTEGRATION LOGISTIC_S3_INT
TO ROLE LOGISTIC_ADMIN;


-- ============================================================
-- 3. VERIFICATION
-- ============================================================

-- Vérification finale de l'intégration
DESC INTEGRATION LOGISTIC_S3_INT;

