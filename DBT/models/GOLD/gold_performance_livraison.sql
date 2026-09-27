{{ config(alias='performance_livraison') }}

SELECT

    CAST("order date (DateOrders)" AS DATE)
        AS "order date (DateOrders)",

    "Shipping Mode",
    "Order Region",
    "Order Country",
    "Market",

    COUNT(DISTINCT "Order Id")
        AS "Nombre de commandes",

    COUNT(DISTINCT CASE
        WHEN "Days for shipping (real)"
             > "Days for shipment (scheduled)"
        THEN "Order Id"
    END) AS "Nombre de commandes en retard",

    ROUND(
        100.0 *
        COUNT(DISTINCT CASE
            WHEN "Days for shipping (real)"
                 > "Days for shipment (scheduled)"
            THEN "Order Id"
        END)
        / NULLIF(COUNT(DISTINCT "Order Id"), 0),
        2
    ) AS "Taux de retard",

    ROUND(
        AVG("Days for shipping (real)"),
        2
    ) AS "Délai moyen réel",

    ROUND(
        AVG("Days for shipment (scheduled)"),
        2
    ) AS "Délai moyen prévu",

    ROUND(
        AVG(
            "Days for shipping (real)"
            - "Days for shipment (scheduled)"
        ),
        2
    ) AS "Écart moyen"

FROM {{ ref('silver_commande') }}

GROUP BY

    CAST("order date (DateOrders)" AS DATE),
    "Shipping Mode",
    "Order Region",
    "Order Country",
    "Market"