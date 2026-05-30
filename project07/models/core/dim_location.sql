WITH dim_location__source AS (
    SELECT *
    FROM {{ ref('stg_ip_location') }}
    WHERE country_code IS NOT NULL
)

,dim_location__rename AS (
    SELECT
        country_code
        ,country_name
        ,region_name
        ,city_name
    FROM dim_location__source
)

,dim_location__cast_type AS (
    SELECT
        CAST(country_code AS STRING) AS country_code
        ,CAST(country_name AS STRING) AS country_name
        ,CAST(region_name AS STRING) AS region_name
        ,CAST(city_name AS STRING) AS city_name
    FROM dim_location__rename
)

,dim_location__gen_key AS (
    SELECT
        FARM_FINGERPRINT(country_code || '|' || region_name || '|' || city_name) AS location_key
        ,country_code
        ,country_name
        ,region_name
        ,city_name
    FROM dim_location__cast_type
)

,dim_location__get_distinct AS (
    SELECT DISTINCT
        location_key
        ,country_code
        ,country_name
        ,region_name
        ,city_name
    FROM dim_location__gen_key
)

,dim_location__add_default_values AS (
    SELECT
        location_key
        ,country_code
        ,country_name
        ,region_name
        ,city_name
    FROM dim_location__get_distinct

    UNION ALL

    SELECT
        -1              AS location_key
        ,'UNKNOWN'      AS country_code
        ,'UNKNOWN'      AS country_name
        ,'UNKNOWN'      AS region_name
        ,'UNKNOWN'      AS city_name
)

SELECT
    location_key
    ,country_code
    ,country_name
    ,region_name
    ,city_name
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_location__add_default_values
