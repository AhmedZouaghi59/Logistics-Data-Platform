{{ config(alias='livraison') }}

SELECT

    TRIM("Shipping Mode") AS "Shipping Mode",
    TRIM("Delivery Status") AS "Delivery Status",

    TRY_TO_NUMBER("Late_delivery_risk") AS "Late_delivery_risk",

    TRY_TO_NUMBER("Days for shipping (real)")
        AS "Days for shipping (real)",

    TRY_TO_NUMBER("Days for shipment (scheduled)")
        AS "Days for shipment (scheduled)",

    TRY_TO_TIMESTAMP(
        "shipping date (DateOrders)",
        'MM/DD/YYYY HH24:MI'
    ) AS "shipping date (DateOrders)"

FROM {{ ref('bronze_livraison') }}