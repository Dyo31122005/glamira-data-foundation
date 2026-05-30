WITH mart_revenue__source AS (
    SELECT *
    FROM {{ ref('fact_sales_order_detail') }}
)

,mart_revenue__join_dims AS (
    SELECT
        d.full_date                                     AS order_date
        ,d.year
        ,d.month
        ,d.month_name
        ,COALESCE(p.category_name, 'Unknown')           AS category_name
        ,COALESCE(p.product_type, 'Unknown')            AS product_type
        ,COALESCE(p.gender, 'Unknown')                  AS gender
        ,COALESCE(l.country_name, 'Unknown')            AS country_name
        ,COALESCE(s.store_country, 'Unknown')           AS store_country
        ,COALESCE(cur.currency_symbol, 'Unknown')       AS currency
        ,COALESCE(cur.currency_name, 'Unknown')         AS currency_name
        ,COALESCE(f.alloy_name, 'Unknown')              AS alloy_name
        ,COALESCE(f.stone_name, 'Unknown')              AS stone_name
        ,f.quantity
        ,f.sale_price
        ,f.sales_amount
        ,CAST(
            f.sales_amount * COALESCE(er.rate_to_eur, 1)
         AS NUMERIC)                                    AS sales_amount_eur
    FROM mart_revenue__source f
    JOIN {{ ref('dim_date') }}          d   ON f.date_key     = d.date_key
    JOIN {{ ref('dim_product') }}       p   ON f.product_key  = p.product_key
    JOIN {{ ref('dim_location') }}      l   ON f.location_key = l.location_key
    JOIN {{ ref('dim_store') }}         s   ON f.store_key    = s.store_key
    JOIN {{ ref('dim_currency') }}      cur ON f.currency_key = cur.currency_key
    JOIN {{ ref('fact_exchange_rate') }} er  ON f.currency_key = er.currency_key
)

SELECT
    order_date
    ,year
    ,month
    ,month_name
    ,category_name
    ,product_type
    ,gender
    ,country_name
    ,store_country
    ,currency
    ,currency_name
    ,alloy_name
    ,stone_name
    ,COUNT(DISTINCT order_date)             AS total_orders
    ,COUNT(*)                               AS total_line_items
    ,SUM(quantity)                          AS total_quantity
    ,ROUND(SUM(sales_amount), 2)            AS total_sales_amount
    ,ROUND(SUM(sales_amount_eur), 2)        AS total_sales_amount_eur
    ,ROUND(AVG(sales_amount_eur), 2)        AS avg_order_value_eur
FROM mart_revenue__join_dims
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
