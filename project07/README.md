# Glamira dbt Project

Data transformation pipeline for Glamira e-commerce analytics using dbt + BigQuery.

## Architecture
glamira_raw (BigQuery)
↓ staging layer  (views)
↓ core layer     (tables: dims + fact)
↓ mart layer     (tables: aggregated for BI)
↓ Looker Studio Dashboards

## Infrastructure

| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| dbt Dataset | glamira_dbt |
| BigQuery Staging | glamira_dbt_staging |
| BigQuery Core | glamira_dbt_core |
| BigQuery Mart | glamira_dbt_mart |

## Project Structure

- **dbt_project.yml** — dbt project configuration
- **seeds/**
  - `exchange_rate_to_eur.csv` — 35 currencies → EUR (Oct-Nov 2019 rates)
- **models/**
  - **staging/** — Views: clean & normalize raw data
    - `sources.yml`
    - `schema.yml`
    - `stg_events_checkout_success.sql`
    - `stg_ip_location.sql`
    - `stg_products.sql`
  - **core/** — Tables: dims + fact
    - `schema.yml`
    - `dim_customer.sql`
    - `dim_date.sql`
    - `dim_location.sql`
    - `dim_product.sql`
    - `dim_store.sql`
    - `fact_sales_order_detail.sql`
  - **mart/** — Tables: aggregated for BI
    - `schema.yml`
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

### Core
| Model | Materialization | Description |
|---|---|---|
| dim_customer | table | Customer dimension — 1 row per device_id, PII masked |
| dim_product | table | Product dimension — name, type, category, price range |
| dim_date | table | Date dimension Apr 2020 - Mar 2021 |
| dim_location | table | Geographic dimension from IP geolocation |
| dim_store | table | Store dimension from checkout URLs — 65 stores, 50+ countries |
| fact_sales_order_detail | table | Fact table — 1 row per product per order |

### Mart
| Model | Materialization | Description |
|---|---|---|
| mart_revenue_summary | table | Revenue by date, product, location, currency |
| mart_geographic_distribution | table | Orders by country/region/city |
| mart_product_performance | table | Product metrics by type/category/metal/stone |
| mart_time_trends | table | Time-based order trends |

## Key Features

### Exchange Rate
- Seed file with 35 currencies converted to EUR (Oct-Nov 2019 fixed rates)
- `sales_amount_eur` added to fact table for cross-currency comparison
- Null currency fallback to EUR (EU store default)

### PII Masking
- `ip` → `ip_hashed` (MD5) in dim_customer
- `email_address` → `email_hashed` (MD5) in dim_customer
- Raw PII not exposed in fact/mart layers

## Data Quality

### JOIN Match Rate
| Dimension | Match Rate | Notes |
|---|---|---|
| dim_customer | 100% | ✅ |
| dim_location | 100% | ✅ |
| dim_store | 100% | ✅ |
| dim_date | 100% | ✅ |
| dim_product | 79.78% | ⚠️ 20.22% missing — crawler Access Denied at source |

### dbt Tests
- 29 data tests (not_null, unique)
- All 29 tests passing

## Setup

```bash
# Activate environment
source ~/glamira-env/bin/activate

# Configure
cd project07
dbt debug

# Run
dbt seed          # load exchange rate
dbt run           # build all models
dbt test          # run 29 tests
dbt docs generate # generate documentation
```

## Dashboards

Looker Studio dashboards:
- Revenue Analysis
- Geographic Distribution
- Time-based Trends
- Product Performance

## Author

Nguyen Minh Dat — May 2026
