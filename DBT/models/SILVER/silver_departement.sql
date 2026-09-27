{{ config(alias='departement') }}

SELECT DISTINCT

    TRY_TO_NUMBER("Department Id") AS "Department Id",

    TRIM("Department Name") AS "Department Name"

FROM {{ ref('bronze_departement') }}