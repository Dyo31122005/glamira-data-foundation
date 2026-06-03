WITH stg_dim_customer__source AS (
    SELECT *
    FROM {{ source('glamira_raw', 'glamira_events') }}
    WHERE device_id IS NOT NULL
        AND TRIM(device_id) != ''
        AND email_address IS NOT NULL
        AND TRIM(email_address) != ''
        AND USER_ID_DB IS NOT NULL
        AND TRIM(USER_ID_DB) != ''
        AND collection != 'checkout_success'
)

,stg_dim_customer__cast_time AS (
    SELECT DISTINCT
        USER_ID_DB                                          AS user_id
        ,device_id
        ,LOWER(TRIM(email_address)) AS email_address
        ,TIMESTAMP_SECONDS(CAST(time_stamp AS INT64))       AS event_timestamp
    FROM stg_dim_customer__source
)

,stg_dim_customer__rank AS (
    SELECT
        user_id
        ,device_id
        ,email_address
        ,event_timestamp
        ,ROW_NUMBER() OVER (
            PARTITION BY user_id, email_address
            ORDER BY event_timestamp ASC
        ) AS rn_asc
        ,ROW_NUMBER() OVER (
            PARTITION BY user_id, email_address
            ORDER BY event_timestamp DESC
        ) AS rn_desc
    FROM stg_dim_customer__cast_time
)

SELECT
    user_id
    ,device_id
    ,email_address
    ,event_timestamp
    ,rn_asc
    ,rn_desc
FROM stg_dim_customer__rank
WHERE rn_asc = 1
    OR rn_desc = 1
