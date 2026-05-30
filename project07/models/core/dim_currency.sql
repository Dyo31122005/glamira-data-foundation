WITH dim_currency__source AS (
    SELECT DISTINCT currency
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE currency IS NOT NULL
)

,dim_currency__rename AS (
    SELECT
        currency AS currency_symbol
        ,CASE currency
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
    FROM dim_currency__source
)

,dim_currency__gen_key AS (
    SELECT
        FARM_FINGERPRINT(currency_symbol) AS currency_key
        ,currency_symbol
        ,currency_name
    FROM dim_currency__rename
)

,dim_currency__get_distinct AS (
    SELECT DISTINCT
        currency_key
        ,currency_symbol
        ,currency_name
    FROM dim_currency__gen_key
)

,dim_currency__add_default_values AS (
    SELECT
        currency_key
        ,currency_symbol
        ,currency_name
    FROM dim_currency__get_distinct

    UNION ALL

    SELECT
        -1 AS currency_key
        ,'UNKNOWN' AS currency_symbol
        ,'UNKNOWN' AS currency_name
)

SELECT
    currency_key
    ,currency_symbol
    ,currency_name
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_currency__add_default_values
