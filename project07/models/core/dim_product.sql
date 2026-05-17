WITH source AS (
    SELECT DISTINCT
        product_id
        ,product_name
        ,sku
        ,category_name
        ,product_type
        ,base_price
        ,min_price
        ,max_price
        ,collection_name
        ,gender
        ,store_code
        ,gold_weight
        ,attribute_set
    FROM {{ ref('stg_products') }}
    WHERE product_id IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY product_id) AS product_key
    ,product_id
    ,product_name
    ,sku
    ,COALESCE(category_name, 'Unknown') AS category_name
    ,CASE 
        WHEN product_type IN ('-1', '--_select_--', NULL) THEN 'Unknown'
        ELSE product_type
    END AS product_type
    ,base_price
    ,min_price
    ,max_price
    ,collection_name
    ,CASE 
        WHEN LOWER(gender) = 'women' THEN 'Women'
        WHEN LOWER(gender) = 'men' THEN 'Men'
        ELSE 'Unisex'
    END AS gender
    ,store_code
    ,CAST(gold_weight AS FLOAT64) AS gold_weight
    ,attribute_set
FROM source
