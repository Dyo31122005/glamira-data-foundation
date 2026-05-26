WITH orders AS (
    SELECT * FROM {{ ref('stg_events_checkout_success') }}
)

,dim_customer AS (
    SELECT * FROM {{ ref('dim_customer') }}
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

,dim_date AS (
    SELECT * FROM {{ ref('dim_date') }}
)

,exchange_rate AS (
    SELECT * FROM {{ ref('exchange_rate_to_eur') }}
)

,joined AS (
    SELECT
        o.order_id
        ,COALESCE(c.customer_key, -1) AS customer_key
        ,COALESCE(p.product_key, -1)  AS product_key
        ,COALESCE(l.location_key, -1) AS location_key
        ,COALESCE(s.store_key, -1)    AS store_key
        ,COALESCE(d.date_key, -1)     AS date_key
        ,DATE(o.event_timestamp)      AS order_date
        ,o.local_time
        ,o.currency
        ,o.currency_name
        ,o.alloy_name
        ,o.stone_name
        ,o.quantity
        ,CAST(o.sale_price AS NUMERIC) AS sale_price
        ,CAST(o.sale_price * o.quantity AS NUMERIC) AS sales_amount
        ,CAST(ROUND(
            o.sale_price * o.quantity * COALESCE(er.rate_to_eur, 1), 2
         ) AS NUMERIC) AS sales_amount_eur
        ,CAST(COALESCE(er.rate_to_eur, 1) AS NUMERIC) AS exchange_rate_to_eur
        ,CURRENT_TIMESTAMP() AS created_at
        ,CURRENT_TIMESTAMP() AS updated_at
    FROM orders o
    LEFT JOIN dim_customer c
        ON o.device_id = c.device_id
    LEFT JOIN dim_product p
        ON o.product_id = p.product_id
    LEFT JOIN {{ ref('stg_ip_location') }} il
        ON o.ip = il.ip
    LEFT JOIN dim_location l
        ON il.country_code = l.country_code
        AND il.region_name = l.region_name
        AND il.city_name = l.city_name
    LEFT JOIN dim_store s
        ON o.store_id = s.store_id
    LEFT JOIN dim_date d
        ON DATE(o.event_timestamp) = d.full_date
    LEFT JOIN exchange_rate er
        ON o.currency = er.currency
)

SELECT
    ROW_NUMBER() OVER (ORDER BY order_date, order_id) AS sales_order_detail_key
    ,order_id
    ,customer_key
    ,product_key
    ,location_key
    ,store_key
    ,date_key
    ,order_date
    ,local_time
    ,currency
    ,currency_name
    ,alloy_name
    ,stone_name
    ,quantity
    ,sale_price
    ,sales_amount
    ,sales_amount_eur
    ,exchange_rate_to_eur
    ,created_at
    ,updated_at
FROM joined
