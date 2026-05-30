WITH dim_customer__source AS (
    SELECT
        device_id
        ,ip
        ,email_address
        ,event_timestamp
        ,ROW_NUMBER() OVER (
            PARTITION BY device_id
            ORDER BY CASE WHEN email_address IS NOT NULL THEN 0 ELSE 1 END
        ) AS rn
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE device_id IS NOT NULL
)

,dim_customer__rename AS (
    SELECT
        device_id
        ,ip
        ,email_address
        ,DATE(event_timestamp) AS first_seen_date
    FROM dim_customer__source
    WHERE rn = 1
)

,dim_customer__cast_type AS (
    SELECT
        CAST(device_id AS STRING)                               AS device_id
        ,TO_HEX(MD5(CAST(ip AS STRING)))                        AS ip_hashed
        ,TO_HEX(MD5(COALESCE(CAST(email_address AS STRING), ''))) AS email_hashed
        ,CASE WHEN email_address IS NOT NULL THEN TRUE ELSE FALSE END AS has_email
        ,CAST(first_seen_date AS DATE)                          AS first_seen_date
    FROM dim_customer__rename
)

,dim_customer__gen_key AS (
    SELECT
        FARM_FINGERPRINT(device_id) AS customer_key
        ,device_id
        ,ip_hashed
        ,email_hashed
        ,has_email
        ,first_seen_date AS effective_date
        ,DATE('9999-12-31') AS expiry_date
        ,TRUE AS is_current
    FROM dim_customer__cast_type
)

,dim_customer__get_distinct AS (
    SELECT DISTINCT
        customer_key
        ,device_id
        ,ip_hashed
        ,email_hashed
        ,has_email
        ,effective_date
        ,expiry_date
        ,is_current
    FROM dim_customer__gen_key
)

,dim_customer__add_default_values AS (
    SELECT
        customer_key
        ,device_id
        ,ip_hashed
        ,email_hashed
        ,has_email
        ,effective_date
        ,expiry_date
        ,is_current
    FROM dim_customer__get_distinct

    UNION ALL

    SELECT
        -1          AS customer_key
        ,'UNKNOWN'  AS device_id
        ,'UNKNOWN'  AS ip_hashed
        ,'UNKNOWN'  AS email_hashed
        ,FALSE      AS has_email
        ,DATE('1900-01-01') AS effective_date
        ,DATE('9999-12-31') AS expiry_date
        ,TRUE       AS is_current
)

SELECT
    customer_key
    ,device_id
    ,email_hashed
    ,has_email
    ,effective_date
    ,expiry_date
    ,is_current
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_customer__add_default_values
