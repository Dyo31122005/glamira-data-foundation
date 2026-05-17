WITH source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'glamira_events') }}
    WHERE collection = 'checkout_success'
        AND cart_products IS NOT NULL
)

,unnested AS (
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
        ,CAST(JSON_VALUE(cp, '$.amount') AS INT64) AS order_qty
        ,JSON_VALUE(cp, '$.price') AS price_raw
        ,JSON_VALUE(cp, '$.currency') AS currency
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'alloy'
            THEN JSON_VALUE(opt, '$.value_label') END) AS alloy_name
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'alloy'
            THEN JSON_VALUE(opt, '$.value_id') END) AS alloy_id
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'diamond'
            THEN JSON_VALUE(opt, '$.value_label') END) AS stone_name
        ,MAX(CASE WHEN JSON_VALUE(opt, '$.option_label') = 'diamond'
            THEN JSON_VALUE(opt, '$.value_id') END) AS stone_id
    FROM source
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(cart_products, '$')) AS cp
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(cp, '$.option')) AS opt
    GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13
)

,cleaned AS (
    SELECT
        event_id
        ,REGEXP_REPLACE(order_id, r'\.0$', '') AS order_id
        ,ip
        ,device_id
        ,NULLIF(TRIM(email_address), '') AS email_address
        ,store_id
        ,event_timestamp
        ,DATE(event_timestamp) AS order_date
        ,local_time
        ,current_url
        ,product_id
        ,order_qty
        ,NULLIF(TRIM(currency), '') AS currency
        ,CASE NULLIF(TRIM(currency), '')
            WHEN '€'       THEN 'Euro'
            WHEN '£'       THEN 'British Pound'
            WHEN '$'       THEN 'US Dollar'
            WHEN 'kr'      THEN 'Scandinavian Krone'
            WHEN 'CHF'     THEN 'Swiss Franc'
            WHEN 'AU $'    THEN 'Australian Dollar'
            WHEN 'CAD $'   THEN 'Canadian Dollar'
            WHEN 'Kč'      THEN 'Czech Koruna'
            WHEN 'Ft'      THEN 'Hungarian Forint'
            WHEN 'zł'      THEN 'Polish Zloty'
            WHEN 'MXN $'   THEN 'Mexican Peso'
            WHEN 'SGD $'   THEN 'Singapore Dollar'
            WHEN 'CLP'     THEN 'Chilean Peso'
            WHEN 'лв.'     THEN 'Bulgarian Lev'
            WHEN 'kn'      THEN 'Croatian Kuna'
            WHEN 'NZD $'   THEN 'New Zealand Dollar'
            WHEN '₺'       THEN 'Turkish Lira'
            WHEN 'COP $'   THEN 'Colombian Peso'
            WHEN 'PEN S/.' THEN 'Peruvian Sol'
            WHEN '₱'       THEN 'Philippine Peso'
            WHEN ' din.'   THEN 'Serbian Dinar'
            WHEN 'HKD $'   THEN 'Hong Kong Dollar'
            WHEN '₫'       THEN 'Vietnamese Dong'
            WHEN 'GTQ Q'   THEN 'Guatemalan Quetzal'
            WHEN 'Lei'     THEN 'Romanian Leu'
            WHEN 'CRC ₡'   THEN 'Costa Rican Colon'
            WHEN 'USD $'   THEN 'US Dollar'
            WHEN '￥'       THEN 'Japanese Yen'
            WHEN '₹'       THEN 'Indian Rupee'
            WHEN 'UYU'     THEN 'Uruguayan Peso'
            WHEN '₲'       THEN 'Paraguayan Guarani'
            WHEN 'DOP $'   THEN 'Dominican Peso'
            WHEN 'BOB Bs'  THEN 'Bolivian Boliviano'
            WHEN 'R$'      THEN 'Brazilian Real'
            ELSE 'Unknown'
        END AS currency_name
        ,alloy_name
        ,alloy_id
        ,stone_name
        ,stone_id
        ,CASE
            WHEN REGEXP_CONTAINS(price_raw, r"'")
                THEN CAST(REGEXP_REPLACE(price_raw, r"'", '') AS FLOAT64)
            WHEN REGEXP_CONTAINS(price_raw, r'\d,\d{2}$')
                THEN CAST(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(price_raw, r'\.', ''),
                    r',', '.') AS FLOAT64)
            WHEN REGEXP_CONTAINS(price_raw, r'\d\.\d{2}$')
                THEN CAST(
                    REGEXP_REPLACE(price_raw, r',', '') AS FLOAT64)
            ELSE NULL
        END AS sales_amount
    FROM unnested
    WHERE product_id IS NOT NULL
)

SELECT *
FROM cleaned
