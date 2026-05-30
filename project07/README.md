# Glamira dbt Project

Data transformation pipeline for Glamira e-commerce analytics using dbt + BigQuery.

## Architecture
glamira_raw (BigQuery)
↓ staging layer  (views)
↓ core layer     (tables: dims + facts)
↓ mart layer     (tables: aggregated for BI)
↓ Looker Studio Dashboards

## Infrastructure

| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| BigQuery Staging | glamira_dbt_staging |
| BigQuery Core | glamira_dbt_core |
| BigQuery Mart | glamira_dbt_mart |

## Project Structure

- **dbt_project.yml** — dbt project configuration
- **packages.yml** — external packages (dbt_utils, dbt_expectations)
- **seeds/**
  - `exchange_rate_to_eur.csv` — 35 currencies → EUR fixed rates (Apr 2020)
- **models/**
  - **staging/** — Views: clean & normalize raw data
    - `_sources.yml`
    - `_glamira_models.yml`
    - `stg_events_checkout_success.sql`
    - `stg_ip_location.sql`
    - `stg_products.sql`
  - **core/** — Tables: dims + facts
    - `_glamira_models.yml`
    - `dim_customer.sql`
    - `dim_date.sql`
    - `dim_location.sql`
    - `dim_product.sql`
    - `dim_store.sql`
    - `dim_currency.sql`
    - `fact_sales_order_detail.sql`
    - `fact_exchange_rate.sql`
  - **mart/** — Tables: aggregated for BI
    - `_glamira_models.yml`
    - `mart_revenue_summary.sql`
    - `mart_geographic_distribution.sql`
    - `mart_product_performance.sql`
    - `mart_time_trends.sql`

## Data Models

### Staging
| Model | Materialization | Description |
|---|---|---|
| stg_events_checkout_success | view | Checkout events with cart products unpivoted, price cleaned |
| stg_ip_location | view | IP geolocation data |
| stg_products | view | Product data from product_react_data_eu |

### Core — Dimensions
| Model | Materialization | Description |
|---|---|---|
| dim_customer | table | Customer dimension — SCD Type 2, PII masked |
| dim_product | table | Product dimension — name, type, category, price range |
| dim_date | table | Date dimension Apr 2020 - Mar 2021 |
| dim_location | table | Geographic dimension from IP geolocation |
| dim_store | table | Store dimension — 65 stores, 50+ countries |
| dim_currency | table | Currency dimension — 35 currencies |

### Core — Facts
| Model | Materialization | Description |
|---|---|---|
| fact_sales_order_detail | incremental (merge) | 1 row per product per order |
| fact_exchange_rate | table | Fixed exchange rates → EUR |

### Mart
| Model | Materialization | Description |
|---|---|---|
| mart_revenue_summary | table | Revenue by date, product, location, currency |
| mart_geographic_distribution | table | Orders by country/region/city |
| mart_product_performance | table | Product metrics by type/category/metal/stone |
| mart_time_trends | table | Time-based order trends |

## Key Features

### CTE Naming Convention
Each model follows a structured CTE pattern:
- `__source` → read from source
- `__rename` → rename columns
- `__cast_type` → cast data types
- `__gen_key` → generate surrogate keys (FARM_FINGERPRINT)
- `__get_distinct` → deduplicate
- `__add_default_values` → add UNKNOWN row (-1)

### Surrogate Keys
All dims use `FARM_FINGERPRINT` for stable, deterministic keys:
```sql
FARM_FINGERPRINT(country_code || '|' || region_name || '|' || city_name) AS location_key
```

### UNKNOWN Rows
All dims include a default `-1` UNKNOWN row for unmatched fact records:
```sql
UNION ALL
SELECT -1 AS location_key, 'UNKNOWN' AS country_code, ...
```

### SCD Type 2 — dim_customer
Tracks customer changes over time:
- `effective_date` — when record became active
- `expiry_date` — when record expired (9999-12-31 = current)
- `is_current` — TRUE if currently active

### Exchange Rate
- Seed file with 35 currencies → EUR (Apr 2020 fixed rates)
- `fact_exchange_rate` stores rates keyed by `currency_key`
- Mart models JOIN `fact_exchange_rate` to compute `sales_amount_eur`

### Incremental Fact
`fact_sales_order_detail` uses incremental merge strategy:
```sql
config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='sales_order_detail_key',
    on_schema_change='append_new_columns'
)
```

### PII Masking
- `email_address` → `email_hashed` (MD5) in dim_customer
- `ip` → `ip_hashed` (MD5) in fact_sales_order_detail
- Raw PII not exposed in fact/mart layers

### Schema Contract
All core models enforce schema contracts:
```yaml
config:
  contract:
    enforced: true
```

## Data Quality

### JOIN Match Rate
| Dimension | Match Rate | Notes |
|---|---|---|
| dim_customer | 100% | ✅ |
| dim_location | 100% | ✅ |
| dim_store | 100% | ✅ |
| dim_date | 100% | ✅ |
| dim_currency | 100% | ✅ |
| dim_product | 100% | ✅ Unmatched products → UNKNOWN row (-1) |

### dbt Tests
- 34 data tests (not_null, unique)
- All 34 tests passing

## Packages

```yaml
packages:
  - package: metaplane/dbt_expectations
    version: 0.10.10
  - package: dbt-labs/dbt_utils
    version: 1.3.3
```

## Setup

```bash
# Activate environment
source ~/glamira-env/bin/activate

# Install packages
cd project07
dbt deps

# Configure
dbt debug

# Run
dbt seed                                        # load exchange rate
dbt run --full-refresh                          # full build all models
dbt run                                         # incremental run
dbt test                                        # run 34 tests
dbt docs generate                               # generate documentation
```

## Dashboards

Looker Studio dashboards:
- Revenue Analysis
- Geographic Distribution
- Time-based Trends
- Product Performance

## Author

Nguyen Minh Dat — May 2026
