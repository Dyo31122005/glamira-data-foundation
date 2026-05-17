WITH fact AS (
    SELECT * FROM {{ ref('fact_sales_order_detail') }}
)

,dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
)

,dim_customer AS (
    SELECT * FROM {{ ref('dim_customer') }}
)

SELECT
    l.country_code
    ,l.country_name
    ,l.region_name
    ,l.city_name
    ,COUNT(DISTINCT fact.order_id) AS total_orders
    ,COUNT(DISTINCT fact.customer_key) AS unique_customers
    ,COUNT(*) AS total_line_items
    ,SUM(fact.order_qty) AS total_quantity
    ,ROUND(SUM(fact.sales_amount), 2) AS total_sales_amount
FROM fact
LEFT JOIN dim_location l ON fact.location_key = l.location_key
LEFT JOIN dim_customer c ON fact.customer_key = c.customer_key
WHERE l.country_name IS NOT NULL
GROUP BY 1,2,3,4
ORDER BY total_orders DESC
