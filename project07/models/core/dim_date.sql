WITH date_spine AS (
    SELECT
        DATE_ADD(DATE('2020-04-01'), INTERVAL n DAY) AS full_date
    FROM UNNEST(GENERATE_ARRAY(0, 364)) AS n
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64) AS date_key
    ,full_date
    ,EXTRACT(HOUR FROM TIMESTAMP(full_date)) AS hour
    ,EXTRACT(DAY FROM full_date) AS day
    ,EXTRACT(MONTH FROM full_date) AS month
    ,FORMAT_DATE('%B', full_date) AS month_name
    ,EXTRACT(YEAR FROM full_date) AS year
    ,EXTRACT(QUARTER FROM full_date) AS quarter
    ,FORMAT_DATE('%A', full_date) AS day_name
    ,CASE WHEN EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7)
        THEN TRUE ELSE FALSE END AS is_weekend
    ,CURRENT_TIMESTAMP() AS created_at
    ,CURRENT_TIMESTAMP() AS updated_at
FROM date_spine
