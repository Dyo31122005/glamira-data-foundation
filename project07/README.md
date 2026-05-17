# Glamira dbt Project

Data transformation pipeline for Glamira e-commerce analytics using dbt + BigQuery.

## Architecture
glamira_raw (BigQuery)
↓
staging layer (views)
↓
core layer (tables: dims + fact)
↓
mart layer (tables: aggregated for BI)
↓
Looker Studio Dashboards

## Models

### Staging
| Model | Description |
|---|---|
| stg_events_checkout_success | Checkout events with cart products unpivoted, price cleaned |
| stg_ip_location | IP geolocation data |
| stg_products | Product data from react_data |

### Core
| Model | Description |
|---|---|
| dim_date | Date dimension Apr 2020 - Mar 2021 |
| dim_customer | Customer dimension with PII masked |
| dim_product | Product dimension with standardized types |
| dim_location | Geographic dimension from IP data |
| dim_store | Store dimension from checkout URLs |
| fact_sales_order_detail | Fact table - 1 row per product per order |

### Mart
| Model | Description |
|---|---|
| mart_revenue_summary | Revenue by date, product, location, currency |
| mart_geographic_distribution | Orders by country/region/city |
| mart_product_performance | Product metrics by type/metal/stone |
| mart_time_trends | Time-based order trends |

## PII Masking
- `ip` → MD5 hashed as `ip_hashed`
- `email_address` → MD5 hashed as `email_hashed`
- Raw PII not exposed in fact/mart layers

## Setup

```bash
# Install
pip install dbt-bigquery

# Configure
cp .env.example .env
dbt debug

# Run
dbt run
dbt test
dbt docs generate
```

## Tests
- 24 data tests (not_null, unique, relationships)
- Run: `dbt test`

## Dashboards
Looker Studio dashboards:
1. Revenue Analysis
2. Geographic Distribution
3. Time-based Trends
4. Product Performance

## Author
Nguyen Minh Dat — May 2026
