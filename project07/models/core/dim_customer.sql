WITH source AS (
    SELECT
        device_id
        ,ip
        ,email_address
        ,ROW_NUMBER() OVER (
            PARTITION BY device_id
            ORDER BY CASE WHEN email_address IS NOT NULL THEN 0 ELSE 1 END
        ) AS rn
    FROM {{ ref('stg_events_checkout_success') }}
    WHERE device_id IS NOT NULL
)

SELECT
    ROW_NUMBER() OVER (ORDER BY device_id) AS customer_key
    ,device_id
    ,TO_HEX(MD5(ip)) AS ip_hashed
    ,TO_HEX(MD5(COALESCE(email_address, ''))) AS email_hashed
    ,CASE WHEN email_address IS NOT NULL THEN TRUE ELSE FALSE END AS has_email
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM source
WHERE rn = 1
