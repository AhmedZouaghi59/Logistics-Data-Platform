{{ config(alias='client') }}

SELECT

    "Customer Id",
    "Customer Email",
    "Customer Fname",
    "Customer Lname",
    "Customer Password",
    "Customer Segment",
    "Customer City",
    "Customer State",
    "Customer Country",
    "Customer Street",
    "Customer Zipcode"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}