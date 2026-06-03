WITH stg_dim_currency__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'glamira_events') }}
    WHERE collection = 'checkout_success'
        AND cart_products IS NOT NULL
)

,stg_dim_currency__unnest AS (
    SELECT
        NULLIF(TRIM(JSON_VALUE(cp, '$.currency')), '') AS currency_symbol
    FROM stg_dim_currency__source
    CROSS JOIN UNNEST(JSON_QUERY_ARRAY(cart_products, '$')) AS cp
)

,stg_dim_currency__rename AS (
    SELECT
        COALESCE(currency_symbol, '€') AS currency_symbol
        ,CASE COALESCE(currency_symbol, '€')
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
            WHEN 'din.'    THEN 'Serbian Dinar'
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
            WHEN 'د.ك.‏'   THEN 'Kuwaiti Dinar'
            ELSE 'Unknown'
        END AS currency_name
    FROM stg_dim_currency__unnest
)

,stg_dim_currency__cast_type AS (
    SELECT
        CAST(currency_symbol AS STRING) AS currency_symbol
        ,CAST(currency_name AS STRING)  AS currency_name
    FROM stg_dim_currency__rename
)

,stg_dim_currency__get_distinct AS (
    SELECT DISTINCT
        currency_symbol
        ,currency_name
    FROM stg_dim_currency__cast_type
)

SELECT *
FROM stg_dim_currency__get_distinct
