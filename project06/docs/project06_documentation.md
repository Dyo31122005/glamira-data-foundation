# Project 06: Data Pipeline & Storage

## Overview
Automated ETL pipeline to export Glamira e-commerce data from MongoDB/local files to Google Cloud Storage and BigQuery raw layer.

## Architecture

```
MongoDB (41M events)          Local Files
        ↓                          ↓
export_to_gcs.py           ip_location.csv
        ↓                  products_final_v2.csv
Google Cloud Storage (GCS)
        ↓
Cloud Function (trigger_bigquery_load)
        ↓
BigQuery (glamira_raw dataset)
```

## Infrastructure

| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| GCS Bucket | raw_glamira_dat3112 |
| VM | glamira-vm-eu (europe-west3-a) |
| BigQuery Dataset | glamira_raw |
| Cloud Function | glamira_bigquery_loader |

## GCS Structure

```
gs://raw_glamira_dat3112/
├── raw_events/
│   ├── glamira_ubl_oct2019_nov2019.tar.gz   # Original raw dump (5.12 GiB)
│   ├── glamira_events.jsonl                  # Extended JSON (32.4 GiB)
│   └── glamira_events_final.jsonl            # Clean standard JSON (34 GiB)
├── ip_location/
│   └── ip_location.csv                       # IP geolocation (148 MiB)
├── products/
│   ├── products_final_v2.csv                 # Product names (3.36 MiB)
│   └── products_to_crawl_1.csv               # Products with URL (2.88 MiB)
└── product_react_data/
    └── products_react_data_eu_flat.jsonl     # React data EU (3.17 GiB)
```

## BigQuery Tables

### glamira_raw.glamira_events
| Column | Type | Description |
|---|---|---|
| _id | STRING | MongoDB document ID |
| time_stamp | INTEGER | Unix timestamp |
| ip | STRING | User IP address |
| user_agent | STRING | Browser user agent |
| resolution | STRING | Screen resolution |
| user_id_db | STRING | User ID |
| device_id | STRING | Device identifier |
| store_id | STRING | Store ID (86 stores) |
| local_time | STRING | Local datetime string |
| current_url | STRING | Page URL |
| referrer_url | STRING | Referrer URL |
| email_address | STRING | User email |
| collection | STRING | Event type |
| product_id | STRING | Product ID |
| order_id | STRING | Order ID (checkout events) |
| option | STRING | Product options (JSON string) |
| cart_products | STRING | Cart items (JSON string) |
| utm_source | STRING | UTM source |
| utm_medium | STRING | UTM medium |

### glamira_raw.ip_location
| Column | Type | Description |
|---|---|---|
| ip | STRING | IP address |
| country_code | STRING | 2-letter country code |
| country_name | STRING | Country name |
| region | STRING | Region/state |
| city | STRING | City name |

### glamira_raw.product_react_data_eu
| Column | Type | Description |
|---|---|---|
| product_id | STRING | Product ID |
| source_url | STRING | Crawled URL |
| url_type | STRING | primary/fallback |
| crawled_at | TIMESTAMP | Crawl timestamp |
| http_status | INTEGER | HTTP status code |
| react_data | STRING | Full react_data JSON |

## Data Profiling Results

### glamira_events
| Metric | Value |
|---|---|
| Total rows | 41,432,473 |
| Unique IPs | 3,239,628 |
| Unique event types | 27 |
| Unique stores | 86 |
| Unique devices | 7,691,556 |
| Null IP | 0 (0%) |
| Null collection | 0 (0%) |
| Null product_id | 19,189,753 (46%) — expected |
| Null email | 39,443,921 (95%) — expected |
| Date range | 2020-04-01 → 2020-06-04 |

### ip_location
| Metric | Value |
|---|---|
| Total rows | 3,239,628 |
| Unique IPs | 3,239,628 |
| Unique countries | 222 |
| Null values | 0 |

### product_react_data_eu
| Metric | Value |
|---|---|
| Total rows | 18,394 |
| Unique products | 18,394 |
| Null values | 0 |
| URL types | 2 (primary/fallback) |
| Crawl period | 2026-05-02 → 2026-05-04 |

## Cloud Function

### Trigger
- **Event**: `google.cloud.storage.object.v1.finalized`
- **Bucket**: `raw_glamira_dat3112`
- **Region**: `asia-southeast1`

### Behavior
Automatically loads new files to BigQuery based on GCS path:

| GCS Path | BigQuery Table | Format |
|---|---|---|
| `raw_events/glamira_events*` | `glamira_events` | JSONL |
| `ip_location/ip_location*` | `ip_location` | CSV |
| `product_react_data/*` | `product_react_data_eu` | JSONL |

### Deploy
```bash
gcloud functions deploy glamira_bigquery_loader \
  --gen2 \
  --runtime=python311 \
  --region=asia-southeast1 \
  --source=cloud_function/ \
  --entry-point=trigger_bigquery_load \
  --trigger-event-filters="type=google.cloud.storage.object.v1.finalized" \
  --trigger-event-filters="bucket=raw_glamira_dat3112" \
  --timeout=540s \
  --memory=512MB \
  --set-env-vars GCP_PROJECT=project-5-unigap,DATASET_ID=glamira_raw
```

## Export Script Usage

```bash
# Setup
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your values

# Export specific collection
python3 scripts/export_to_gcs.py --collection events
python3 scripts/export_to_gcs.py --collection ip
python3 scripts/export_to_gcs.py --collection products

# Export all
python3 scripts/export_to_gcs.py --all
```

## Issues & Solutions

| Issue | Solution |
|---|---|
| Disk full during BSON export | Expanded VM disk from 100GB to 200GB |
| bsondump Extended JSON not supported by BigQuery | Wrote Python converter to standard JSON |
| `show_recommendation` field type conflict | Defined explicit schema with all STRING types |
| Akamai WAF blocks GCP IPs | Used Playwright headless browser on VM EU |
| Cloud Function auth error | Granted `roles/run.invoker` to Eventarc SA |

## Author
Nguyen Minh Dat — May 2026
