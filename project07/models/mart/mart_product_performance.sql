WITH fact AS (
    SELECT * FROM {{ ref('fact_sales_order_detail') }}
)

,dim_product AS (
    SELECT * FROM {{ ref('dim_product') }}
)

,dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
)

SELECT
    p.product_id
    ,p.product_name
    ,p.category_name
    ,p.product_type
    ,p.gender
    ,p.collection_name
    ,p.base_price
    ,p.min_price
    ,p.max_price
    ,fact.alloy_name AS metal_type
    ,fact.stone_name AS stone_type
    ,d.year
    ,d.month
    ,d.month_name
    ,COUNT(DISTINCT fact.order_id) AS total_orders
    ,SUM(fact.order_qty) AS total_quantity
    ,ROUND(SUM(fact.sales_amount), 2) AS total_sales_amount
FROM fact
LEFT JOIN dim_product p ON fact.product_key = p.product_key
LEFT JOIN dim_date d ON fact.date_key = d.date_key
WHERE p.product_id IS NOT NULL
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14
ORDER BY total_orders DESC
