WITH fact_exchange_rate__source AS (
    SELECT *
    FROM {{ ref('exchange_rate_to_eur') }}
)

,fact_exchange_rate__rename AS (
    SELECT
        currency AS currency_symbol
        ,rate_to_eur
    FROM fact_exchange_rate__source
)

,fact_exchange_rate__cast_type AS (
    SELECT
        CAST(currency_symbol AS STRING) AS currency_symbol
        ,CAST(rate_to_eur AS NUMERIC)   AS rate_to_eur
    FROM fact_exchange_rate__rename
)

,fact_exchange_rate__gen_key AS (
    SELECT
        c.currency_key
        ,f.rate_to_eur
    FROM fact_exchange_rate__cast_type f
    JOIN {{ ref('dim_currency') }} c
        ON f.currency_symbol = c.currency_symbol
)

SELECT
    FARM_FINGERPRINT(CAST(currency_key AS STRING)) AS exchange_rate_key
    ,currency_key
    ,rate_to_eur
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM fact_exchange_rate__gen_key
