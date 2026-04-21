# Glamira Data Foundation

Data collection & storage foundation for Glamira e-commerce analytics (Oct–Nov 2019).

## Architecture

```
Raw Data (tar.gz)
        ↓ mongorestore
MongoDB (41M events)
        ↓                      ↓
IP Geolocation          Product Collection
3,239,628 IPs           19,417 products
        ↓                      ↓
GCS + BigQuery          GCS + BigQuery
```

## Infrastructure

| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| GCS Bucket | raw_glamira_dat3112 |
| VM | glamira-vm (e2-medium, 100GB) |
| OS | Ubuntu 22.04 LTS |
| MongoDB | 7.0.31 |

## Project Structure

```
glamira-data-foundation/
├── README.md
├── .gitignore
├── scripts/
│   ├── ip_location.py        # IP geolocation processing
│   ├── get_products.py       # Product data collection
│   ├── extract_names.py      # Product name extraction from URL
│   └── crawl_products.py     # Product name crawling (backup)
├── data/
│   ├── products_to_crawl_1.csv   # 19,417 products with URL
│   ├── products_final_v2.csv     # Products with name (CSV)
│   └── products_final_v2.json    # Products with name (JSON)
└── docs/
    ├── data_dictionary.md            # Data structure documentation
    ├── project05_documentation.md    # Full setup & delivery report
    └── project_summary.json          # Project summary
```

> **Note:** `ip_location.csv` and `ip_location.json` are stored on GCS only
> due to GitHub file size limits (148MB and 436MB respectively).

## Key Results

| Metric | Value |
|---|---|
| Total events | 41,432,473 |
| Unique users (IPs) | 3,239,628 |
| Unique products | 19,417 |
| Product name coverage | 99.3% |
| Countries | 85 |

## Usage

### Prerequisites
```bash
pip install IP2Location pymongo pandas requests beautifulsoup4
```

### 1. IP Geolocation Processing
```bash
python3 scripts/ip_location.py
```
Reads unique IPs from MongoDB → looks up location → saves to `ip_location.csv` + MongoDB collection.

### 2. Product Collection
```bash
python3 scripts/get_products.py
```
Filters 7 event types → deduplicates by `product_id` → saves to `products_to_crawl_1.csv`.

### 3. Product Name Extraction
```bash
python3 scripts/extract_names.py
```
Extracts product name from URL pattern — no HTTP requests, no rate limiting.

## Top Markets

| Country | Unique Users |
|---|---|
| Germany | 348,555 |
| United Kingdom | 249,294 |
| United States | 222,893 |
| France | 215,713 |
| Italy | 153,396 |

## BigQuery Tables

| Table | Rows | Description |
|---|---|---|
| glamira_raw.ip_location | 3,239,628 | IP + location data |
| glamira_raw.products_full | 19,417 | Products + URL |
| glamira_raw.products_final_v2 | 19,417 | Products + name |

## Data Quality

| Check | Expected | Actual |
|---|---|---|# Glamira Data Foundation

Data collection & storage foundation for Glamira e-commerce analytics (Oct–Nov 2019).

## Architecture

```
Raw Data (tar.gz)
        ↓ mongorestore
MongoDB (41M events)
        ↓                      ↓
IP Geolocation          Product Collection
3,239,628 IPs           19,417 products
        ↓                      ↓
GCS + BigQuery          GCS + BigQuery
```

## Infrastructure

| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| GCS Bucket | raw_glamira_dat3112 |
| VM | glamira-vm (e2-medium, 100GB) |
| OS | Ubuntu 22.04 LTS |
| MongoDB | 7.0.31 |

## Project Structure

```
glamira-data-foundation/
├── README.md
├── .gitignore
├── scripts/
│   ├── ip_location.py        # IP geolocation processing
│   ├── get_products.py       # Product data collection
│   ├── extract_names.py      # Product name extraction from URL
│   └── crawl_products.py     # Product name crawling (backup)
├── data/
│   ├── products_to_crawl_1.csv   # 19,417 products with URL
│   ├── products_final_v2.csv     # Products with name (CSV)
│   └── products_final_v2.json    # Products with name (JSON)
└── docs/
    ├── data_dictionary.md            # Data structure documentation
    ├── project05_documentation.md    # Full setup & delivery report
    └── project_summary.json          # Project summary
```

> **Note:** `ip_location.csv` and `ip_location.json` are stored on GCS only
> due to GitHub file size limits (148MB and 436MB respectively).

## Key Results

| Metric | Value |
|---|---|
| Total events | 41,432,473 |
| Unique users (IPs) | 3,239,628 |
| Unique products | 19,417 |
| Product name coverage | 99.3% |
| Countries | 85 |

## Usage

### Prerequisites
```bash
pip install IP2Location pymongo pandas requests beautifulsoup4
```

### 1. IP Geolocation Processing
```bash
python3 scripts/ip_location.py
```
Reads unique IPs from MongoDB → looks up location → saves to `ip_location.csv` + MongoDB collection.

### 2. Product Collection
```bash
python3 scripts/get_products.py
```
Filters 7 event types → deduplicates by `product_id` → saves to `products_to_crawl_1.csv`.

### 3. Product Name Extraction
```bash
python3 scripts/extract_names.py
```
Extracts product name from URL pattern — no HTTP requests, no rate limiting.

## Top Markets

| Country | Unique Users |
|---|---|
| Germany | 348,555 |
| United Kingdom | 249,294 |
| United States | 222,893 |
| France | 215,713 |
| Italy | 153,396 |

## BigQuery Tables

| Table | Rows | Description |
|---|---|---|
| glamira_raw.ip_location | 3,239,628 | IP + location data |
| glamira_raw.products_full | 19,417 | Products + URL |
| glamira_raw.products_final_v2 | 19,417 | Products + name |

## Data Quality

| Check | Expected | Actual |
|---|---|---|
| Total events | ~41M | 41,432,473 |
| Unique IPs | ~3.2M | 3,239,628 |
| Unique products | >7,000 | 19,417 |
| Name coverage | >90% | 99.3% |
| IP errors | 0 | 0 |

## Issues & Solutions

| Issue | Solution |
|---|---|
| Disk full (20GB) during extraction | Expanded disk to 100GB |
| `distinct()` exceeds 16MB limit | Used `aggregate()` with `allowDiskUse=True` |
| RAM overload during processing | Implemented batch processing + streaming |
| Crawler blocked by Glamira | Extracted names from URL pattern instead |
| Script killed mid-run | Used `nohup` + incremental batch saving |

## Security Notes

- MongoDB binds to `127.0.0.1` only — not exposed to internet
- Port 27017 closed to external traffic
- GCS bucket is private
- No service account keys in code

## Author

Nguyen Minh Dat — April 2026
| Total events | ~41M | 41,432,473 |
| Unique IPs | ~3.2M | 3,239,628 |
| Unique products | >7,000 | 19,417 |
| Name coverage | >90% | 99.3% |
| IP errors | 0 | 0 |

## Issues & Solutions

| Issue | Solution |
|---|---|
| Disk full (20GB) during extraction | Expanded disk to 100GB |
| `distinct()` exceeds 16MB limit | Used `aggregate()` with `allowDiskUse=True` |
| RAM overload during processing | Implemented batch processing + streaming |
| Crawler blocked by Glamira | Extracted names from URL pattern instead |
| Script killed mid-run | Used `nohup` + incremental batch saving |

## Security Notes

- MongoDB binds to `127.0.0.1` only — not exposed to internet
- Port 27017 closed to external traffic
- GCS bucket is private
- No service account keys in code

## Author

Nguyen Minh Dat — April 2026