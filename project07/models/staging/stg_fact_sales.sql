WITH stg_fact_sales__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'glamira_events') }}
    WHERE collection = 'checkout_success'
        AND cart_products IS NOT NULL
)

,stg_fact_sales__unnest AS (
    SELECT
        _id AS event_id
        ,order_id
        ,ip
        ,device_id
        ,email_address
        ,store_id
        ,TIMESTAMP_SECONDS(CAST(time_stamp AS INT64)) AS event_timestamp
        ,local_time
        ,current_url
        ,JSON_VALUE(cp, '$.product_id') AS product_id
        ,CAST(JSON_VALUE(cp, '$.amount') AS INT64) AS quantity
        ,JSON_VALUE(cp, '$.price') AS price_raw
        ,NULLIF(TRIM(JSON_VALUE(cp, '$.currency')), '') AS currency_raw
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'alloy'
            THEN JSON_VALUE(opt, '$.value_label') END) AS alloy_name
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'diamond'
            THEN JSON_VALUE(opt, '$.value_label') END) AS stone_name
    FROM stg_fact_sales__source
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(cart_products, '$')) AS cp
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(cp, '$.option')) AS opt
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
)

,stg_fact_sales__rename AS (
    SELECT
        event_id
        ,REGEXP_REPLACE(order_id, r'\.0$', '') AS order_id
        ,ip
        ,device_id
        ,NULLIF(TRIM(email_address), '') AS email_address
        ,CAST(store_id AS STRING) AS store_id
        ,event_timestamp
        ,DATE(event_timestamp) AS order_date
        ,local_time
        ,current_url
        ,product_id
        ,quantity
        ,COALESCE(currency_raw, '€') AS currency
        ,alloy_name
        ,stone_name
        ,price_raw
    FROM stg_fact_sales__unnest
    WHERE product_id IS NOT NULL
)

,stg_fact_sales__cast_type AS (
    SELECT
        CAST(event_id AS STRING) AS event_id
        ,CAST(order_id AS STRING) AS order_id
        ,CAST(ip AS STRING) AS ip
        ,CAST(device_id AS STRING) AS device_id
        ,CAST(email_address AS STRING) AS email_address
        ,CAST(store_id AS STRING) AS store_id
        ,CAST(event_timestamp AS TIMESTAMP) AS event_timestamp
        ,CAST(order_date AS DATE) AS order_date
        ,CAST(local_time AS TIMESTAMP) AS local_time
        ,CAST(current_url AS STRING) AS current_url
        ,CAST(product_id AS STRING) AS product_id
        ,CAST(quantity AS INT64) AS quantity
        ,CAST(currency AS STRING) AS currency
        ,CAST(alloy_name AS STRING) AS alloy_name
        ,CAST(stone_name AS STRING) AS stone_name
        ,CASE
            WHEN REGEXP_CONTAINS(price_raw, r"'")
                THEN CAST(REGEXP_REPLACE(price_raw, r"'", '') AS FLOAT64)
            WHEN REGEXP_CONTAINS(price_raw, r'\d,\d{2}$')
                THEN CAST(REGEXP_REPLACE(
                        REGEXP_REPLACE(price_raw, r'\.', ''),
                    r',', '.') AS FLOAT64)
            WHEN REGEXP_CONTAINS(price_raw, r'\d\.\d{2}$')
                THEN CAST(REGEXP_REPLACE(price_raw, r',', '') AS FLOAT64)
            ELSE NULL
        END AS sale_price
    FROM stg_fact_sales__rename
)

SELECT *
FROM stg_fact_sales__cast_type
