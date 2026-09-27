{{ config(alias='localisation') }}

SELECT DISTINCT

    TRIM("Order City") AS "Order City",
    TRIM("Order State") AS "Order State",
    TRIM("Order Country") AS "Order Country",
    TRIM("Order Region") AS "Order Region",
    TRIM("Order Zipcode") AS "Order Zipcode",
    TRIM("Market") AS "Market",

    TRY_TO_DECIMAL("Latitude", 10, 6) AS "Latitude",
    TRY_TO_DECIMAL("Longitude", 10, 6) AS "Longitude"

FROM {{ ref('bronze_localisation') }}