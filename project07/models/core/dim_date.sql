WITH date_spine AS (
    SELECT
        DATE_ADD(DATE('2020-04-01'), INTERVAL n DAY) AS date_day
    FROM UNNEST(GENERATE_ARRAY(0, 364)) AS n
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', date_day) AS INT64) AS date_key
    ,date_day AS full_date
    ,EXTRACT(YEAR FROM date_day) AS year
    ,EXTRACT(QUARTER FROM date_day) AS quarter
    ,EXTRACT(MONTH FROM date_day) AS month
    ,FORMAT_DATE('%B', date_day) AS month_name
    ,EXTRACT(WEEK FROM date_day) AS week_of_year
    ,EXTRACT(DAY FROM date_day) AS day_of_month
    ,EXTRACT(DAYOFWEEK FROM date_day) AS day_of_week
    ,FORMAT_DATE('%A', date_day) AS day_name
    ,CASE WHEN EXTRACT(DAYOFWEEK FROM date_day) IN (1, 7) 
        THEN TRUE ELSE FALSE END AS is_weekend
FROM date_spine
