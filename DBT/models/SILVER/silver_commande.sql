{{ config(alias='commande') }}

SELECT

    "Type",

    TRY_TO_NUMBER("Order Id") AS "Order Id",
    TRY_TO_NUMBER("Order Customer Id") AS "Order Customer Id",
    TRY_TO_NUMBER("Customer Id") AS "Customer Id",
    TRY_TO_NUMBER("Product Card Id") AS "Product Card Id",
    TRY_TO_NUMBER("Order Item Cardprod Id") AS "Order Item Cardprod Id",
    TRY_TO_NUMBER("Order Item Id") AS "Order Item Id",
    TRY_TO_NUMBER("Department Id") AS "Department Id",

    TRY_TO_TIMESTAMP(
        "order date (DateOrders)",
        'MM/DD/YYYY HH24:MI') AS "order date (DateOrders)",

    TRY_TO_TIMESTAMP(
        "shipping date (DateOrders)",
        'MM/DD/YYYY HH24:MI') AS "shipping date (DateOrders)",

    TRIM("Order Status") AS "Order Status",
    TRIM("Shipping Mode") AS "Shipping Mode",
    TRIM("Delivery Status") AS "Delivery Status",

    TRY_TO_NUMBER("Late_delivery_risk") AS "Late_delivery_risk",
    TRY_TO_NUMBER("Days for shipping (real)") AS "Days for shipping (real)",
    TRY_TO_NUMBER("Days for shipment (scheduled)") AS "Days for shipment (scheduled)",
    TRY_TO_NUMBER("Order Item Quantity") AS "Order Item Quantity",
    TRY_TO_NUMBER("Category Id") AS "Category Id",

    TRY_TO_DECIMAL("Order Item Product Price", 18, 2) AS "Order Item Product Price",
    TRY_TO_DECIMAL("Order Item Discount", 18, 2) AS "Order Item Discount",
    TRY_TO_DECIMAL("Order Item Discount Rate", 10, 4) AS "Order Item Discount Rate",
    TRY_TO_DECIMAL("Order Item Total", 18, 2) AS "Order Item Total",
    TRY_TO_DECIMAL("Sales", 18, 2) AS "Sales",
    TRY_TO_DECIMAL("Sales per customer", 18, 2) AS "Sales per customer",
    TRY_TO_DECIMAL("Benefit per order", 18, 2) AS "Benefit per order",
    TRY_TO_DECIMAL("Order Profit Per Order", 18, 2) AS "Order Profit Per Order",
    TRY_TO_DECIMAL("Order Item Profit Ratio", 10, 4) AS "Order Item Profit Ratio",

    TRIM("Order City") AS "Order City",
    TRIM("Order State") AS "Order State",
    TRIM("Order Country") AS "Order Country",
    TRIM("Order Region") AS "Order Region",
    TRIM("Order Zipcode") AS "Order Zipcode",
    TRIM("Market") AS "Market",
    TRIM("Category Name") AS "Category Name"

FROM {{ ref('bronze_commande') }}