WITH dim_product__source AS (
    SELECT *
    FROM {{ ref('stg_products') }}
    WHERE product_id IS NOT NULL
)

,dim_product__rename AS (
    SELECT
        product_id
        ,product_name
        ,category_name
        ,product_type
        ,base_price
        ,min_price
        ,max_price
        ,collection_name
        ,gender
    FROM dim_product__source
)

,dim_product__cast_type AS (
    SELECT
        CAST(product_id AS STRING) AS product_id
        ,CAST(COALESCE(product_name, 'Unknown') AS STRING) AS product_name
        ,CAST(COALESCE(category_name, 'Unknown') AS STRING) AS category_name
        ,CAST(CASE
            WHEN product_type IN ('-1', '--_select_--') OR product_type IS NULL THEN 'Unknown'
            ELSE product_type
        END AS STRING) AS product_type
        ,CAST(COALESCE(collection_name, 'Unknown') AS STRING) AS collection_name
        ,CAST(CASE
            WHEN LOWER(gender) = 'women' THEN 'Women'
            WHEN LOWER(gender) = 'men'   THEN 'Men'
            ELSE 'Unisex'
        END AS STRING) AS gender
        ,CAST(base_price AS NUMERIC) AS base_price
        ,CAST(min_price AS NUMERIC)  AS min_price
        ,CAST(max_price AS NUMERIC)  AS max_price
    FROM dim_product__rename
)

,dim_product__gen_key AS (
    SELECT
        FARM_FINGERPRINT(product_id) AS product_key
        ,product_id
        ,product_name
        ,category_name
        ,product_type
        ,collection_name
        ,gender
        ,base_price
        ,min_price
        ,max_price
    FROM dim_product__cast_type
)

,dim_product__get_distinct AS (
    SELECT DISTINCT
        product_key
        ,product_id
        ,product_name
        ,category_name
        ,product_type
        ,collection_name
        ,gender
        ,base_price
        ,min_price
        ,max_price
    FROM dim_product__gen_key
)

,dim_product__add_default_values AS (
    SELECT
        product_key
        ,product_id
        ,product_name
        ,category_name
        ,product_type
        ,collection_name
        ,gender
        ,base_price
        ,min_price
        ,max_price
    FROM dim_product__get_distinct

    UNION ALL

    SELECT
        -1          AS product_key
        ,'UNKNOWN'  AS product_id
        ,'UNKNOWN'  AS product_name
        ,'UNKNOWN'  AS category_name
        ,'UNKNOWN'  AS product_type
        ,'UNKNOWN'  AS collection_name
        ,'UNKNOWN'  AS gender
        ,0          AS base_price
        ,0          AS min_price
        ,0          AS max_price
)

SELECT
    product_key
    ,product_id
    ,product_name
    ,category_name
    ,product_type
    ,collection_name
    ,gender
    ,base_price
    ,min_price
    ,max_price
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_product__add_default_values
