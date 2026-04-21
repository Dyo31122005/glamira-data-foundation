# Glamira Analytics Foundation

## Overview
Data collection & storage foundation for Glamira e-commerce analytics (Oct–Nov 2019).

## Architecture
Raw Data (tar.gz)
↓ mongorestore
MongoDB (41M events)
↓                    ↓
IP Geolocation         Product Collection
3,239,628 IPs          19,417 products
↓                    ↓
GCS + BigQuery         GCS + BigQuery

## Infrastructure
| Component | Details |
|---|---|
| GCP Project | project-5-unigap |
| Region | asia-southeast1 |
| GCS Bucket | raw_glamira_dat3112 |
| VM | glamira-vm (e2-medium, 100GB) |
| MongoDB | 7.0.31 |

## Project Structure
glamira-analytics-foundation/
├── README.md
├── scripts/
│   ├── ip_location.py       # IP geolocation processing
│   ├── get_products.py      # Product data collection
│   ├── extract_names.py     # Product name extraction
│   └── crawl_products.py    # Product name crawling
├── data/
│   ├── ip_location.csv          # 3,239,628 IPs + location
│   ├── ip_location.json         # Same data in JSON
│   ├── products_to_crawl_1.csv  # 19,417 products + URL
│   ├── products_final_v2.csv    # Products + name (CSV)
│   └── products_final_v2.json   # Products + name (JSON)
└── docs/
├── data_dictionary.md           # Data structure docs
├── project05_documentation.md   # Full delivery report
└── project_summary.json         # Project summary

## Key Results
| Metric | Value |
|---|---|
| Total events | 41,432,473 |
| Unique users (IPs) | 3,239,628 |
| Unique products | 19,417 |
| Product name coverage | 99.3% |
| Stores | 85 countries |

## Usage

### IP Geolocation
```bash
python3 scripts/ip_location.py
```

### Product Collection
```bash
python3 scripts/get_products.py
python3 scripts/extract_names.py
```

## Dependencies
```bash
pip install IP2Location pymongo pandas requests beautifulsoup4
```

## Author
Nguyen Minh Dat — April 2026
