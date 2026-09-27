{{ config(alias='performance_produit') }}

SELECT

    c."Product Card Id",
    p."Product Name",
    p."Category Name",

    c."Department Id",
    d."Department Name",

    SUM(c."Order Item Quantity")
        AS "Quantité vendue",

    ROUND(
        SUM(c."Sales"),
        2
    ) AS "Chiffre d'affaires",

    ROUND(
        SUM(c."Order Item Discount"),
        2
    ) AS "Remises",

    ROUND(
        SUM(c."Order Profit Per Order"),
        2
    ) AS "Profit",

    COUNT(DISTINCT c."Order Id")
        AS "Nombre de commandes"

FROM {{ ref('silver_commande') }} c

LEFT JOIN {{ ref('silver_produit') }} p
    ON c."Product Card Id" = p."Product Card Id"

LEFT JOIN {{ ref('silver_departement') }} d
    ON c."Department Id" = d."Department Id"

GROUP BY

    c."Product Card Id",
    p."Product Name",
    p."Category Name",
    c."Department Id",
    d."Department Name"