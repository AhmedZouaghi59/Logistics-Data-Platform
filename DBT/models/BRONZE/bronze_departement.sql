{{ config(alias='departement') }}

SELECT

    "Department Id",
    "Department Name"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}