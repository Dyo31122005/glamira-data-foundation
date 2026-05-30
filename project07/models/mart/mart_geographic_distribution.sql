WITH mart_geo__source AS (
    SELECT *
    FROM {{ ref('fact_sales_order_detail') }}
)

,mart_geo__join_dims AS (
    SELECT
        l.country_code
        ,l.country_name
        ,l.region_name
        ,l.city_name
        ,f.order_id
        ,f.customer_key
        ,f.quantity
        ,f.sales_amount
        ,CAST(
            f.sales_amount * COALESCE(er.rate_to_eur, 1)
         AS NUMERIC)                AS sales_amount_eur
    FROM mart_geo__source f
    JOIN {{ ref('dim_location') }}      l   ON f.location_key = l.location_key
    JOIN {{ ref('dim_currency') }}      cur ON f.currency_key = cur.currency_key
    JOIN {{ ref('fact_exchange_rate') }} er  ON f.currency_key = er.currency_key
    WHERE l.country_name != 'UNKNOWN'
)

SELECT
    country_code
    ,country_name
    ,region_name
    ,city_name
    ,COUNT(DISTINCT order_id)           AS total_orders
    ,COUNT(DISTINCT customer_key)       AS unique_customers
    ,COUNT(*)                           AS total_line_items
    ,SUM(quantity)                      AS total_quantity
    ,ROUND(SUM(sales_amount_eur), 2)    AS total_sales_amount_eur
FROM mart_geo__join_dims
GROUP BY 1,2,3,4
ORDER BY total_orders DESC
