WITH mart_product__source AS (
    SELECT *
    FROM {{ ref('fact_sales_order_detail') }}
)

,mart_product__join_dims AS (
    SELECT
        p.product_id
        ,p.product_name
        ,p.category_name
        ,p.product_type
        ,p.gender
        ,p.collection_name
        ,f.alloy_name
        ,f.stone_name
        ,d.year
        ,d.month
        ,d.month_name
        ,f.order_id
        ,f.quantity
        ,f.sales_amount
        ,CAST(
            f.sales_amount * COALESCE(er.rate_to_eur, 1)
         AS NUMERIC)                AS sales_amount_eur
        ,CAST(
            f.sale_price * COALESCE(er.rate_to_eur, 1)
         AS NUMERIC)                AS sale_price_eur
    FROM mart_product__source f
    JOIN {{ ref('dim_product') }}       p   ON f.product_key  = p.product_key
    JOIN {{ ref('dim_date') }}          d   ON f.date_key     = d.date_key
    JOIN {{ ref('dim_currency') }}      cur ON f.currency_key = cur.currency_key
    JOIN {{ ref('fact_exchange_rate') }} er  ON f.currency_key = er.currency_key
    WHERE p.product_id != 'UNKNOWN'
)

SELECT
    product_id
    ,product_name
    ,category_name
    ,product_type
    ,gender
    ,collection_name
    ,alloy_name
    ,stone_name
    ,year
    ,month
    ,month_name
    ,COUNT(DISTINCT order_id)           AS total_orders
    ,SUM(quantity)                      AS total_quantity
    ,ROUND(SUM(sales_amount_eur), 2)    AS total_sales_amount_eur
    ,ROUND(AVG(sale_price_eur), 2)      AS avg_sale_price_eur
FROM mart_product__join_dims
GROUP BY 1,2,3,4,5,6,7,8,9,10,11
ORDER BY total_orders DESC
