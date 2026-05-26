WITH source AS (
    SELECT DISTINCT
        product_id
        ,product_name
        ,category_name
        ,product_type
        ,base_price
        ,min_price
        ,max_price
        ,collection_name
        ,gender
    FROM {{ ref('stg_products') }}
    WHERE product_id IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key
    ,product_id
    ,COALESCE(product_name, 'Unknown') AS product_name
    ,COALESCE(category_name, 'Unknown') AS category_name
    ,CASE
        WHEN product_type IN ('-1', '--_select_--') OR product_type IS NULL THEN 'Unknown'
        ELSE product_type
    END AS product_type
    ,COALESCE(collection_name, 'Unknown') AS collection_name
    ,CASE
        WHEN LOWER(gender) = 'women' THEN 'Women'
        WHEN LOWER(gender) = 'men'   THEN 'Men'
        ELSE 'Unisex'
    END AS gender
    ,CAST(base_price AS NUMERIC) AS base_price
    ,CAST(min_price AS NUMERIC)  AS min_price
    ,CAST(max_price AS NUMERIC)  AS max_price
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM source
