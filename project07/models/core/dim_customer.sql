WITH dim_customer__source AS (
    SELECT *
    FROM {{ ref('stg_dim_customer') }}
)

,dim_customer__get_valid_from AS (
    SELECT
        user_id
        ,device_id
        ,email_address
        ,event_timestamp AS valid_from
    FROM dim_customer__source
    WHERE rn_asc = 1
)

,dim_customer__get_valid_to AS (
    SELECT
        user_id
        ,email_address
        ,event_timestamp AS valid_to
    FROM dim_customer__source
    WHERE rn_desc = 1
)

,dim_customer__join AS (
    SELECT
        f.user_id
        ,f.device_id
        ,f.email_address
        ,f.valid_from
        ,t.valid_to
    FROM dim_customer__get_valid_from f
    LEFT JOIN dim_customer__get_valid_to t
        ON f.user_id = t.user_id
        AND f.email_address = t.email_address
)

,dim_customer__find_latest_email_per_user AS (
    -- Email mới nhất của mỗi user (theo valid_to)
    SELECT
        user_id
        ,email_address AS latest_email
        ,valid_to AS latest_valid_to
    FROM dim_customer__join
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY valid_to DESC
    ) = 1
)

,dim_customer__mark_current AS (
    -- Đánh dấu row nào là current
    SELECT
        d.user_id
        ,d.device_id
        ,d.email_address
        ,d.valid_from
        ,d.valid_to
        ,CASE WHEN d.email_address = l.latest_email THEN TRUE ELSE FALSE END AS is_latest
    FROM dim_customer__join d
    LEFT JOIN dim_customer__find_latest_email_per_user l
        ON d.user_id = l.user_id
)

,dim_customer__final_dates AS (
    -- Với current row: dùng valid_to làm valid_from (lần cuối dùng email = lần quay lại)
    -- Với historical row: giữ nguyên
    SELECT
        user_id
        ,device_id
        ,email_address
        ,CASE
            WHEN is_latest THEN valid_to
            ELSE valid_from
        END                                     AS valid_from
        ,CASE
            WHEN is_latest THEN TIMESTAMP('3000-01-01')
            ELSE valid_to
        END                                     AS valid_to
        ,CASE
            WHEN is_latest THEN 'Y'
            ELSE 'N'
        END                                     AS is_current
    FROM dim_customer__mark_current
)

,dim_customer__gen_key AS (
    SELECT
        FARM_FINGERPRINT(
            user_id || '|' || COALESCE(NULLIF(TRIM(email_address), ''), 'UNKNOWN')
        )                                       AS customer_key
        ,user_id
        ,device_id
        ,COALESCE(NULLIF(TRIM(email_address), ''), 'UNKNOWN') AS email
        ,valid_from
        ,valid_to
        ,is_current
    FROM dim_customer__final_dates
)

,dim_customer__get_distinct AS (
    SELECT DISTINCT
        customer_key
        ,user_id
        ,device_id
        ,email
        ,valid_from
        ,valid_to
        ,is_current
    FROM dim_customer__gen_key
)

,dim_customer__add_default_values AS (
    SELECT
        customer_key
        ,user_id
        ,device_id
        ,email
        ,valid_from
        ,valid_to
        ,is_current
    FROM dim_customer__get_distinct

    UNION ALL

    SELECT
        -1                          AS customer_key
        ,'UNKNOWN'                  AS user_id
        ,'UNKNOWN'                  AS device_id
        ,'UNKNOWN'                  AS email
        ,TIMESTAMP('1900-01-01')    AS valid_from
        ,TIMESTAMP('3000-01-01')    AS valid_to
        ,'Y'                        AS is_current
)

SELECT
    customer_key
    ,user_id
    ,device_id
    ,email
    ,valid_from
    ,valid_to
    ,is_current
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM dim_customer__add_default_values
