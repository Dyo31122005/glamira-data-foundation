WITH stg_ip_location__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'ip_location') }}
    WHERE ip IS NOT NULL
)

,stg_ip_location__rename AS (
    SELECT
        ip
        ,country_code
        ,country_name
        ,region AS region_name
        ,city AS city_name
    FROM stg_ip_location__source
)

,stg_ip_location__cast_type AS (
    SELECT
        CAST(ip AS STRING) AS ip
        ,CAST(UPPER(TRIM(country_code)) AS STRING) AS country_code
        ,CAST(TRIM(country_name) AS STRING) AS country_name
        ,CAST(TRIM(region_name) AS STRING) AS region_name
        ,CAST(TRIM(city_name) AS STRING) AS city_name
    FROM stg_ip_location__rename
)

SELECT *
FROM stg_ip_location__cast_type
