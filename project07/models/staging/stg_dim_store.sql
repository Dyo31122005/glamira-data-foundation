WITH stg_dim_store__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'glamira_events') }}
    WHERE collection = 'checkout_success'
        AND cart_products IS NOT NULL
        AND store_id IS NOT NULL
        AND TRIM(CAST(store_id AS STRING)) != ''
)

,stg_dim_store__rename AS (
    SELECT
        CAST(store_id AS STRING) AS store_id
        ,current_url
    FROM stg_dim_store__source
)

,stg_dim_store__cast_type AS (
    SELECT
        CAST(store_id AS STRING)     AS store_id
        ,CAST(current_url AS STRING) AS current_url
    FROM stg_dim_store__rename
)

,stg_dim_store__get_distinct AS (
    SELECT DISTINCT
        store_id
        ,current_url
    FROM stg_dim_store__cast_type
)

SELECT *
FROM stg_dim_store__get_distinct
