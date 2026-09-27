{{ config(alias='commande') }}

SELECT

    "Type",

    "Order Id",
    "Order Customer Id",
    "Customer Id",

    "Product Card Id",
    "Order Item Cardprod Id",
    "Order Item Id",

    "Department Id",

    "order date (DateOrders)",
    "shipping date (DateOrders)",

    "Order Status",

    "Shipping Mode",
    "Delivery Status",
    "Late_delivery_risk",

    "Days for shipping (real)",
    "Days for shipment (scheduled)",

    "Order Item Quantity",
    "Order Item Product Price",
    "Order Item Discount",
    "Order Item Discount Rate",
    "Order Item Total",

    "Sales",
    "Sales per customer",
    "Benefit per order",
    "Order Profit Per Order",
    "Order Item Profit Ratio",

    "Order City",
    "Order State",
    "Order Country",
    "Order Region",
    "Order Zipcode",
    "Market",

    "Category Id",
    "Category Name"

FROM {{ source('logistic_bronze', 'RAW_DATACO') }}