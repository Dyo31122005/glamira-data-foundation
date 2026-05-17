WITH fact AS (
    SELECT * FROM {{ ref('fact_sales_order_detail') }}
)

,dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
)

,dim_product AS (
    SELECT * FROM {{ ref('dim_product') }}
)

,dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
)

,dim_store AS (
    SELECT * FROM {{ ref('dim_store') }}
)

SELECT
    d.full_date AS order_date
    ,d.year
    ,d.month
    ,d.month_name
    ,d.week_of_year
    ,COALESCE(p.category_name, 'Unknown') AS category_name
    ,COALESCE(p.product_type, 'Unknown') AS product_type
    ,COALESCE(p.gender, 'Unknown') AS gender
    ,COALESCE(l.country_name, 'Unknown') AS country_name
    ,COALESCE(l.region_name, 'Unknown') AS region_name
    ,COALESCE(s.store_country, 'Unknown') AS store_country
    ,fact.currency
    ,fact.currency_name
    ,COALESCE(fact.alloy_name, 'Unknown') AS metal_type
    ,COALESCE(fact.stone_name, 'Unknown') AS stone_type
    ,COUNT(DISTINCT fact.order_id) AS total_orders
    ,COUNT(*) AS total_line_items
    ,SUM(fact.order_qty) AS total_quantity
    ,ROUND(SUM(fact.sales_amount), 2) AS total_sales_amount
    ,ROUND(AVG(fact.sales_amount), 2) AS avg_order_value
FROM fact
LEFT JOIN dim_date d ON fact.date_key = d.date_key
LEFT JOIN dim_product p ON fact.product_key = p.product_key
LEFT JOIN dim_location l ON fact.location_key = l.location_key
LEFT JOIN dim_store s ON fact.store_key = s.store_key
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
