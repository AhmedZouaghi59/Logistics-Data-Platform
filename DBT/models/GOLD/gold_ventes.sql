{{ config(alias='ventes') }}

SELECT

    CAST(c."order date (DateOrders)" AS DATE)
        AS "order date (DateOrders)",

    c."Product Card Id",
    p."Product Name",
    p."Category Name",

    c."Department Id",
    d."Department Name",

    c."Market",

    SUM(c."Order Item Quantity")
        AS "Order Item Quantity",

    SUM(c."Sales")
        AS "Sales",

    SUM(c."Order Item Discount")
        AS "Order Item Discount",

    COUNT(DISTINCT c."Order Id")
        AS "Nombre de commandes"

FROM {{ ref('silver_commande') }} c

LEFT JOIN {{ ref('silver_produit') }} p
    ON c."Product Card Id" = p."Product Card Id"

LEFT JOIN {{ ref('silver_departement') }} d
    ON c."Department Id" = d."Department Id"

GROUP BY

    CAST(c."order date (DateOrders)" AS DATE),
    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name",
    c."Market"