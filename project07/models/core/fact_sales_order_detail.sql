WITH orders AS (
    SELECT *
    FROM {{ ref('stg_events_checkout_success') }}
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

,joined AS (
    SELECT
        o.event_id
        ,o.order_id
        ,c.customer_key
        ,COALESCE(p.product_key, -1) AS product_key
        ,COALESCE(l.location_key, -1) AS location_key
        ,COALESCE(s.store_key, -1) AS store_key
        ,COALESCE(d.date_key, -1) AS date_key
        ,o.product_id
        ,o.order_qty
        ,o.sales_amount
        ,o.currency
        ,o.currency_name
        ,o.alloy_name
        ,o.alloy_id
        ,o.stone_name
        ,o.stone_id
        ,o.order_date
        ,o.event_timestamp
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
)

SELECT
    event_id
    ,order_id
    ,customer_key
    ,product_key
    ,location_key
    ,store_key
    ,date_key
    ,product_id
    ,order_qty
    ,sales_amount
    ,currency
    ,currency_name
    ,alloy_name
    ,alloy_id
    ,stone_name
    ,stone_id
    ,order_date
    ,event_timestamp
FROM joined
