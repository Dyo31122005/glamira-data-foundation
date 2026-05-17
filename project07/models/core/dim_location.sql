WITH source AS (
    SELECT DISTINCT
        country_code
        ,country_name
        ,region_name
        ,city_name
    FROM {{ ref('stg_ip_location') }}
    WHERE country_code IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY country_code, region_name, city_name) AS location_key
    ,country_code
    ,country_name
    ,region_name
    ,city_name
FROM source
