{{ config(alias='localisation') }}

SELECT

    "Order City",
    "Order State",
    "Order Country",
    "Order Region",
    "Order Zipcode",
    "Market",
    "Latitude",
    "Longitude"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}