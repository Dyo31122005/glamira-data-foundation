WITH source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'product_react_data_eu') }}
    WHERE product_id IS NOT NULL
)

SELECT
    product_id
    ,JSON_VALUE(react_data, '$.name') AS product_name
    ,JSON_VALUE(react_data, '$.sku') AS sku
    ,JSON_VALUE(react_data, '$.category_name') AS category_name
    ,JSON_VALUE(react_data, '$.product_type') AS product_type
    ,CAST(JSON_VALUE(react_data, '$.price') AS FLOAT64) AS base_price
    ,CAST(JSON_VALUE(react_data, '$.min_price') AS FLOAT64) AS min_price
    ,CAST(JSON_VALUE(react_data, '$.max_price') AS FLOAT64) AS max_price
    ,JSON_VALUE(react_data, '$.collection') AS collection_name
    ,JSON_VALUE(react_data, '$.gender') AS gender
    ,JSON_VALUE(react_data, '$.store_code') AS store_code
    ,JSON_VALUE(react_data, '$.gold_weight') AS gold_weight
    ,JSON_VALUE(react_data, '$.attribute_set') AS attribute_set
FROM source
