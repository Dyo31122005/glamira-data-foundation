WITH source AS (
    SELECT DISTINCT
        store_id
        ,current_url
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE store_id IS NOT NULL
)

,store_country AS (
    SELECT
        store_id
        ,REGEXP_EXTRACT(current_url, r'www\.glamira\.([a-z.]+)\/') AS store_domain
    FROM source
)

SELECT
    ROW_NUMBER() OVER (ORDER BY store_id) AS store_key
    ,CAST(store_id AS STRING) AS store_id
    ,store_domain
    ,CASE 
        WHEN store_domain = 'com' THEN 'United States'
        WHEN store_domain = 'de' THEN 'Germany'
        WHEN store_domain = 'co.uk' THEN 'United Kingdom'
        WHEN store_domain = 'fr' THEN 'France'
        WHEN store_domain = 'it' THEN 'Italy'
        WHEN store_domain = 'es' THEN 'Spain'
        WHEN store_domain = 'nl' THEN 'Netherlands'
        WHEN store_domain = 'at' THEN 'Austria'
        WHEN store_domain = 'ch' THEN 'Switzerland'
        WHEN store_domain = 'com.au' THEN 'Australia'
        WHEN store_domain = 'ca' THEN 'Canada'
        ELSE store_domain
    END AS store_country
FROM store_country
