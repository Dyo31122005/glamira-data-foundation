WITH source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'ip_location') }}
    WHERE ip IS NOT NULL
)

SELECT
    ip
    ,UPPER(TRIM(country_code)) AS country_code
    ,TRIM(country_name) AS country_name
    ,TRIM(region) AS region_name
    ,TRIM(city) AS city_name
FROM source
