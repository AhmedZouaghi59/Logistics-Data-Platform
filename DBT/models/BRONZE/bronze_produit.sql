{{ config(alias='produit') }}

SELECT

    "Product Card Id",
    "Product Category Id",
    "Product Name",
    "Product Description",
    "Product Image",
    "Product Price",
    "Product Status",
    "Category Id",
    "Category Name"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}