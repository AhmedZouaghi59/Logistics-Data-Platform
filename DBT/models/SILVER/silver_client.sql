{{ config(alias='client') }}

SELECT DISTINCT

    TRY_TO_NUMBER("Customer Id") AS "Customer Id",

    TRIM("Customer Email") AS "Customer Email",
    TRIM("Customer Fname") AS "Customer Fname",
    TRIM("Customer Lname") AS "Customer Lname",
    TRIM("Customer Password") AS "Customer Password",
    TRIM("Customer Segment") AS "Customer Segment",
    TRIM("Customer City") AS "Customer City",
    TRIM("Customer State") AS "Customer State",
    TRIM("Customer Country") AS "Customer Country",
    TRIM("Customer Street") AS "Customer Street",
    TRIM("Customer Zipcode") AS "Customer Zipcode"

FROM {{ ref('bronze_client') }}