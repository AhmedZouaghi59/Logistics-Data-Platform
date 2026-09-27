{{ config(alias='livraison') }}

SELECT

    "Shipping Mode",
    "Delivery Status",
    "Late_delivery_risk",
    "Days for shipping (real)",
    "Days for shipment (scheduled)",
    "shipping date (DateOrders)"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}