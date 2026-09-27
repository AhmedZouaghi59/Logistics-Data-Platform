-- ============================================================
-- 1. CONFIGURATION
-- ============================================================

USE ROLE LOGISTIC_ADMIN;

USE DATABASE LOGISTIC_DWH;
USE WAREHOUSE LOGISTIC_WH.
USE SCHEMA BRONZE;


-- ============================================================
-- 2. RAW DATACO
-- ============================================================

-- Couche Bronze :
-- - structure issue de la source DataCo
-- - noms des colonnes conservés
-- - toutes les colonnes en VARCHAR
-- - aucun typage métier
-- - aucun nettoyage métier

CREATE TABLE IF NOT EXISTS BRONZE.RAW_DATACO (
    "Type" VARCHAR,
    "Days for shipping (real)" VARCHAR,
    "Days for shipment (scheduled)" VARCHAR,
    "Benefit per order" VARCHAR,
    "Sales per customer" VARCHAR,
    "Delivery Status" VARCHAR,
    "Late_delivery_risk" VARCHAR,
    "Category Id" VARCHAR,
    "Category Name" VARCHAR,
    "Customer City" VARCHAR,
    "Customer Country" VARCHAR,
    "Customer Email" VARCHAR,
    "Customer Fname" VARCHAR,
    "Customer Id" VARCHAR,
    "Customer Lname" VARCHAR,
    "Customer Password" VARCHAR,
    "Customer Segment" VARCHAR,
    "Customer State" VARCHAR,
    "Customer Street" VARCHAR,
    "Customer Zipcode" VARCHAR,
    "Department Id" VARCHAR,
    "Department Name" VARCHAR,
    "Latitude" VARCHAR,
    "Longitude" VARCHAR,
    "Market" VARCHAR,
    "Order City" VARCHAR,
    "Order Country" VARCHAR,
    "Order Customer Id" VARCHAR,
    "order date (DateOrders)" VARCHAR,
    "Order Id" VARCHAR,
    "Order Item Cardprod Id" VARCHAR,
    "Order Item Discount" VARCHAR,
    "Order Item Discount Rate" VARCHAR,
    "Order Item Id" VARCHAR,
    "Order Item Product Price" VARCHAR,
    "Order Item Profit Ratio" VARCHAR,
    "Order Item Quantity" VARCHAR,
    "Sales" VARCHAR,
    "Order Item Total" VARCHAR,
    "Order Profit Per Order" VARCHAR,
    "Order Region" VARCHAR,
    "Order State" VARCHAR,
    "Order Status" VARCHAR,
    "Order Zipcode" VARCHAR,
    "Product Card Id" VARCHAR,
    "Product Category Id" VARCHAR,
    "Product Description" VARCHAR,
    "Product Image" VARCHAR,
    "Product Name" VARCHAR,
    "Product Price" VARCHAR,
    "Product Status" VARCHAR,
    "shipping date (DateOrders)" VARCHAR,
    "Shipping Mode" VARCHAR
);


-- ============================================================
-- 3. CHARGEMENT DATACO DEPUIS S3
-- ============================================================

COPY INTO BRONZE.RAW_DATACO
FROM @STAGE_DATACO
FILE_FORMAT = (
    FORMAT_NAME = 'FF_DATACO_CSV'
)
ON_ERROR = 'ABORT_STATEMENT';


-- ============================================================
-- 4. CONTROLES
-- ============================================================

-- Nombre de lignes chargées
SELECT
    'RAW_DATACO' AS TABLE_NAME,
    COUNT(*) AS NB_LIGNES
FROM LOGISTIC_DWH.BRONZE.RAW_DATACO;


-- Aperçu des données
SELECT *
FROM LOGISTIC_DWH.BRONZE.RAW_DATACO
LIMIT 5;


-- Vérification de la structure
DESC TABLE LOGISTIC_DWH.BRONZE.RAW_DATACO;