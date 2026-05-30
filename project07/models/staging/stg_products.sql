WITH stg_products__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'product_react_data_eu') }}
    WHERE product_id IS NOT NULL
)

,stg_products__rename AS (
    SELECT
        product_id
        ,JSON_VALUE(react_data, '$.name') AS product_name
        ,JSON_VALUE(react_data, '$.category_name') AS category_name
        ,JSON_VALUE(react_data, '$.product_type') AS product_type
        ,JSON_VALUE(react_data, '$.price') AS base_price
        ,JSON_VALUE(react_data, '$.min_price') AS min_price
        ,JSON_VALUE(react_data, '$.max_price') AS max_price
        ,JSON_VALUE(react_data, '$.collection') AS collection_name
        ,JSON_VALUE(react_data, '$.gender') AS gender
    FROM stg_products__source
)

,stg_products__cast_type AS (
    SELECT
        CAST(product_id AS STRING) AS product_id
        ,CAST(product_name AS STRING) AS product_name
        ,CAST(category_name AS STRING) AS category_name
        ,CAST(product_type AS STRING) AS product_type
        ,CAST(base_price AS FLOAT64) AS base_price
        ,CAST(min_price AS FLOAT64) AS min_price
        ,CAST(max_price AS FLOAT64) AS max_price
        ,CAST(collection_name AS STRING) AS collection_name
        ,CAST(gender AS STRING) AS gender
    FROM stg_products__rename
)

SELECT *
FROM stg_products__cast_type
