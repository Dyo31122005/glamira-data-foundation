WITH dim_currency__source AS (
    SELECT *
    FROM {{ ref('stg_dim_currency') }}
)

,dim_currency__gen_key AS (
    SELECT
        FARM_FINGERPRINT(currency_symbol) AS currency_key
        ,currency_symbol
        ,currency_name
    FROM dim_currency__source
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
        -1          AS currency_key
        ,'UNKNOWN'  AS currency_symbol
        ,'UNKNOWN'  AS currency_name
)

SELECT
    currency_key
    ,currency_symbol
    ,currency_name
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_currency__add_default_values
