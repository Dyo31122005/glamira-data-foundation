WITH dim_store__source AS (
    SELECT
        store_id
        ,current_url
        ,ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY
                CASE
                    WHEN REGEXP_CONTAINS(current_url, r'www\.glamira\.') THEN 0
                    WHEN REGEXP_CONTAINS(current_url, r'ring-paare\.') THEN 1
                    ELSE 2
                END
            ,current_url
        ) AS rn
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE store_id IS NOT NULL
)

,dim_store__rename AS (
    SELECT
        store_id
        ,current_url
        ,REGEXP_EXTRACT(current_url, r'www\.glamira\.([a-z.]+)\/') AS domain_from_www
        ,REGEXP_EXTRACT(current_url, r'glamira\.(?:de|local)/([a-z]{2,4})/') AS path_code
        ,REGEXP_CONTAINS(current_url, r'ring-paare\.') AS is_ring_paare
    FROM dim_store__source
    WHERE rn = 1
)

,dim_store__cast_type AS (
    SELECT
        CAST(store_id AS STRING) AS store_id
        ,COALESCE(domain_from_www,
            CASE path_code
                WHEN 'glde' THEN 'de'
                WHEN 'glgb' THEN 'co.uk'
                WHEN 'glus' THEN 'com'
                WHEN 'glmt' THEN 'com.mt'
                WHEN 'cotr' THEN 'com.tr'
                WHEN 'glse' THEN 'se'
                WHEN 'glat' THEN 'at'
                WHEN 'glfr' THEN 'fr'
                WHEN 'glit' THEN 'it'
                WHEN 'gles' THEN 'es'
                WHEN 'glnl' THEN 'nl'
                WHEN 'glch' THEN 'ch'
            END
        ) AS store_domain
        ,is_ring_paare
    FROM dim_store__rename
)

,dim_store__gen_key AS (
    SELECT
        FARM_FINGERPRINT(store_id) AS store_key
        ,store_id
        ,CASE WHEN is_ring_paare THEN 'ring-paare.de' ELSE store_domain END AS store_domain
        ,CASE
            WHEN is_ring_paare           THEN 'Germany'
            WHEN store_domain = 'de'     THEN 'Germany'
            WHEN store_domain = 'co.uk'  THEN 'United Kingdom'
            WHEN store_domain = 'fr'     THEN 'France'
            WHEN store_domain = 'it'     THEN 'Italy'
            WHEN store_domain = 'es'     THEN 'Spain'
            WHEN store_domain = 'nl'     THEN 'Netherlands'
            WHEN store_domain = 'at'     THEN 'Austria'
            WHEN store_domain = 'ch'     THEN 'Switzerland'
            WHEN store_domain = 'sk'     THEN 'Slovakia'
            WHEN store_domain = 'lv'     THEN 'Latvia'
            WHEN store_domain = 'pt'     THEN 'Portugal'
            WHEN store_domain = 'bg'     THEN 'Bulgaria'
            WHEN store_domain = 'hu'     THEN 'Hungary'
            WHEN store_domain = 'rs'     THEN 'Serbia'
            WHEN store_domain = 'com.mt' THEN 'Malta'
            WHEN store_domain = 'dk'     THEN 'Denmark'
            WHEN store_domain = 'fi'     THEN 'Finland'
            WHEN store_domain = 'no'     THEN 'Norway'
            WHEN store_domain = 'be'     THEN 'Belgium'
            WHEN store_domain = 'hr'     THEN 'Croatia'
            WHEN store_domain = 'lt'     THEN 'Lithuania'
            WHEN store_domain = 'ee'     THEN 'Estonia'
            WHEN store_domain = 'cz'     THEN 'Czech Republic'
            WHEN store_domain = 'ie'     THEN 'Ireland'
            WHEN store_domain = 'pl'     THEN 'Poland'
            WHEN store_domain = 'md'     THEN 'Moldova'
            WHEN store_domain = 'se'     THEN 'Sweden'
            WHEN store_domain = 'com.tr' THEN 'Turkey'
            WHEN store_domain = 'ro'     THEN 'Romania'
            WHEN store_domain = 'si'     THEN 'Slovenia'
            WHEN store_domain = 'com'    THEN 'United States'
            WHEN store_domain = 'ca'     THEN 'Canada'
            WHEN store_domain = 'com.br' THEN 'Brazil'
            WHEN store_domain = 'com.mx' THEN 'Mexico'
            WHEN store_domain = 'com.ar' THEN 'Argentina'
            WHEN store_domain = 'com.bo' THEN 'Bolivia'
            WHEN store_domain = 'com.co' THEN 'Colombia'
            WHEN store_domain = 'com.do' THEN 'Dominican Republic'
            WHEN store_domain = 'com.ec' THEN 'Ecuador'
            WHEN store_domain = 'com.gt' THEN 'Guatemala'
            WHEN store_domain = 'com.pe' THEN 'Peru'
            WHEN store_domain = 'com.uy' THEN 'Uruguay'
            WHEN store_domain = 'com.py' THEN 'Paraguay'
            WHEN store_domain = 'com.pr' THEN 'Puerto Rico'
            WHEN store_domain = 'co.cr'  THEN 'Costa Rica'
            WHEN store_domain = 'cl'     THEN 'Chile'
            WHEN store_domain = 'co.nz'  THEN 'New Zealand'
            WHEN store_domain = 'com.au' THEN 'Australia'
            WHEN store_domain = 'vn'     THEN 'Vietnam'
            WHEN store_domain = 'cn'     THEN 'China'
            WHEN store_domain = 'jp'     THEN 'Japan'
            WHEN store_domain = 'sg'     THEN 'Singapore'
            WHEN store_domain = 'hk'     THEN 'Hong Kong'
            WHEN store_domain = 'in'     THEN 'India'
            WHEN store_domain = 'com.ph' THEN 'Philippines'
            WHEN store_domain = 'ae'     THEN 'United Arab Emirates'
            WHEN store_domain = 'com.kw' THEN 'Kuwait'
            WHEN store_domain = 'co.za'  THEN 'South Africa'
            ELSE 'Unknown'
        END AS store_country
    FROM dim_store__cast_type
)

,dim_store__get_distinct AS (
    SELECT DISTINCT
        store_key
        ,store_id
        ,store_domain
        ,store_country
    FROM dim_store__gen_key
)

,dim_store__add_default_values AS (
    SELECT
        store_key
        ,store_id
        ,store_domain
        ,store_country
    FROM dim_store__get_distinct

    UNION ALL

    SELECT
        -1          AS store_key
        ,'UNKNOWN'  AS store_id
        ,'UNKNOWN'  AS store_domain
        ,'UNKNOWN'  AS store_country
)

SELECT
    store_key
    ,store_id
    ,store_domain
    ,store_country
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_store__add_default_values
