{{ config(alias='produit') }}

SELECT DISTINCT

    TRY_TO_NUMBER("Product Card Id") AS "Product Card Id",
    TRY_TO_NUMBER("Product Category Id") AS "Product Category Id",
    TRY_TO_NUMBER("Product Status") AS "Product Status",
    TRY_TO_NUMBER("Category Id") AS "Category Id",

    TRIM("Product Name") AS "Product Name",
    TRIM("Product Description") AS "Product Description",
    TRIM("Product Image") AS "Product Image",
    TRY_TO_DECIMAL("Product Price", 18, 2) AS "Product Price",
    TRIM("Category Name") AS "Category Name"

FROM {{ ref('bronze_produit') }}