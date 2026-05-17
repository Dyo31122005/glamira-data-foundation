WITH source AS (
    SELECT DISTINCT
        device_id
        ,ip
        ,email_address
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE device_id IS NOT NULL
)

,with_location AS (
    SELECT
        s.device_id
        ,s.ip
        ,s.email_address
        ,l.country_code
        ,l.country_name
        ,l.region_name
        ,l.city_name
    FROM source s
    LEFT JOIN {{ ref('stg_ip_location') }} l
        ON s.ip = l.ip
)

SELECT
    ROW_NUMBER() OVER (ORDER BY device_id) AS customer_key
    ,device_id
    -- PII Masking
    ,TO_HEX(MD5(ip)) AS ip_hashed
    ,TO_HEX(MD5(COALESCE(email_address, ''))) AS email_hashed
    ,CASE WHEN email_address IS NOT NULL THEN TRUE ELSE FALSE END AS has_email
    ,country_code
    ,country_name
    ,region_name
    ,city_name
FROM with_location
