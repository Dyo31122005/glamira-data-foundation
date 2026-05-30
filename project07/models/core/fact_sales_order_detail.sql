{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='sales_order_detail_key',
        on_schema_change='append_new_columns'
    )
}}

WITH fact_sales__source AS (
    SELECT *
    FROM {{ ref('stg_events_checkout_success') }}
    {% if is_incremental() %}
    WHERE DATE(event_timestamp) >= DATE_ADD(current_date(), INTERVAL -3 DAY)
    {% endif %}
)

,fact_sales__join_dims AS (
    SELECT
        o.event_id
        ,o.order_id
        ,COALESCE(c.customer_key, -1)   AS customer_key
        ,COALESCE(p.product_key, -1)    AS product_key
        ,COALESCE(l.location_key, -1)   AS location_key
        ,COALESCE(s.store_key, -1)      AS store_key
        ,COALESCE(cur.currency_key, -1) AS currency_key
        ,COALESCE(d.date_key, -1)       AS date_key
        ,COALESCE(o.local_time, TIMESTAMP('3000-01-01')) AS local_time
        ,TO_HEX(MD5(COALESCE(o.ip, 'UNKNOWN'))) AS ip_hashed
        ,o.alloy_name
        ,o.stone_name
        ,COALESCE(o.quantity, 0)        AS quantity
        ,CAST(COALESCE(o.sale_price, 0) AS NUMERIC) AS sale_price
        ,CAST(
            COALESCE(o.sale_price, 0) * COALESCE(o.quantity, 0)
         AS NUMERIC)                    AS sales_amount
    FROM fact_sales__source o
    JOIN {{ ref('dim_customer') }} c
        ON o.device_id = c.device_id
        AND c.is_current = TRUE
    JOIN {{ ref('dim_product') }} p
        ON o.product_id = p.product_id
    JOIN {{ ref('stg_ip_location') }} il
        ON o.ip = il.ip
    JOIN {{ ref('dim_location') }} l
        ON il.country_code = l.country_code
        AND il.region_name = l.region_name
        AND il.city_name = l.city_name
    JOIN {{ ref('dim_store') }} s
        ON o.store_id = s.store_id
    JOIN {{ ref('dim_currency') }} cur
        ON o.currency = cur.currency_symbol
    JOIN {{ ref('dim_date') }} d
        ON DATE(o.event_timestamp) = d.full_date
)

,fact_sales__rank AS (
    SELECT
        *
        ,ROW_NUMBER() OVER (
            PARTITION BY order_id, product_key
            ORDER BY local_time DESC, sale_price DESC, quantity DESC
        ) AS rn
    FROM fact_sales__join_dims
)

,fact_sales__remove_dup AS (
    SELECT *
    FROM fact_sales__rank
    WHERE rn = 1
)

SELECT
    FARM_FINGERPRINT(
        order_id || '|' || CAST(product_key AS STRING)
    )                   AS sales_order_detail_key
    ,customer_key
    ,product_key
    ,location_key
    ,store_key
    ,currency_key
    ,date_key
    ,order_id
    ,ip_hashed
    ,local_time
    ,alloy_name
    ,stone_name
    ,quantity
    ,sale_price
    ,sales_amount
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM fact_sales__remove_dup
