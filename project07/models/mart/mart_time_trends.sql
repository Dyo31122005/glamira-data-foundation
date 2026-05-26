WITH fact AS (
    SELECT * FROM {{ ref('fact_sales_order_detail') }}
)

,dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
)

,dim_store AS (
    SELECT * FROM {{ ref('dim_store') }}
)

SELECT
    d.full_date AS order_date
    ,d.year
    ,d.month
    ,d.month_name
    ,d.day_name
    ,d.is_weekend
    ,s.store_country
    ,fact.currency
    ,fact.currency_name
    ,COUNT(DISTINCT fact.order_id)        AS total_orders
    ,COUNT(DISTINCT fact.customer_key)    AS unique_customers
    ,SUM(fact.quantity)                   AS total_quantity
    ,ROUND(SUM(fact.sales_amount_eur), 2) AS total_sales_amount_eur
FROM fact
LEFT JOIN dim_date d  ON fact.date_key  = d.date_key
LEFT JOIN dim_store s ON fact.store_key = s.store_key
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY order_date
