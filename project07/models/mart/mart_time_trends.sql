WITH mart_time__source AS (
    SELECT *
    FROM {{ ref('fact_sales_order_detail') }}
)

,mart_time__join_dims AS (
    SELECT
        d.full_date                                     AS order_date
        ,d.year
        ,d.month
        ,d.month_name
        ,d.day_name
        ,d.is_weekend
        ,COALESCE(s.store_country, 'Unknown')           AS store_country
        ,COALESCE(cur.currency_symbol, 'Unknown')       AS currency
        ,COALESCE(cur.currency_name, 'Unknown')         AS currency_name
        ,f.order_id
        ,f.customer_key
        ,f.quantity
        ,f.sales_amount
        ,CAST(
            f.sales_amount * COALESCE(er.rate_to_eur, 1)
         AS NUMERIC)                                    AS sales_amount_eur
    FROM mart_time__source f
    JOIN {{ ref('dim_date') }}          d   ON f.date_key     = d.date_key
    JOIN {{ ref('dim_store') }}         s   ON f.store_key    = s.store_key
    JOIN {{ ref('dim_currency') }}      cur ON f.currency_key = cur.currency_key
    JOIN {{ ref('fact_exchange_rate') }} er  ON f.currency_key = er.currency_key
)

SELECT
    order_date
    ,year
    ,month
    ,month_name
    ,day_name
    ,is_weekend
    ,store_country
    ,currency
    ,currency_name
    ,COUNT(DISTINCT order_id)           AS total_orders
    ,COUNT(DISTINCT customer_key)       AS unique_customers
    ,SUM(quantity)                      AS total_quantity
    ,ROUND(SUM(sales_amount_eur), 2)    AS total_sales_amount_eur
FROM mart_time__join_dims
GROUP BY 1,2,3,4,5,6,7,8,9
ORDER BY order_date
