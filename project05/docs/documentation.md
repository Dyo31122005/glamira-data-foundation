# Data Collection & Storage Foundation
## Documentation & Delivery Report

**Author:** Nguyen Minh Dat  
**Date:** April 2026  
---

## 1. Infrastructure Setup

### Google Cloud Platform
| Component | Value |
|---|---|
| Project ID | project-5-unigap |
| Region | asia-southeast1 (Singapore) |
| GCS Bucket | raw_glamira_dat3112 |

### Virtual Machine
| Component | Value |
|---|---|
| Name | glamira-vm |
| Machine type | e2-medium (2 vCPU, 4GB RAM) |
| OS | Ubuntu 22.04 LTS |
| Disk | 100GB Balanced persistent disk |
| Zone | asia-southeast1-c |

### MongoDB
| Component | Value |
|---|---|
| Version | 7.0.31 |
| Port | 27017 |
| Bind IP | 127.0.0.1 (localhost only) |
| Database | countly |
| Collection | summary |

---

## 2. Data Loading

### Source Files
- glamira_ubl_oct2019_nov2019.tar.gz (5.2GB)
- IP-COUNTRY-REGION-CITY.BIN (137MB)

### Import Process
```bash
tar -xzvf glamira_ubl_oct2019_nov2019.tar.gz -C ~/
mongorestore --db countly --collection summary ~/dump/countly/summary.bson
```

### Import Result
| Metric | Value |
|---|---|
| Total documents | 41,432,473 |
| Time range | Oct - Nov 2019 |
| Failures | 0 |

---

## 3. IP Geolocation 

### Process
1. Aggregate 3,239,628 unique IPs from MongoDB
2. Look up location using IP2Location + .BIN file
3. Save to MongoDB collection + CSV

### Results
| Metric | Value |
|---|---|
| Unique IPs | 3,239,628 |
| Errors | 0 |
| Coverage | 100% |

### Top 10 Countries
| Country | Users |
|---|---|
| Germany | 348,555 |
| United Kingdom | 249,294 |
| United States | 222,893 |
| France | 215,713 |
| Italy | 153,396 |
| Spain | 147,887 |
| Turkey | 131,138 |
| Romania | 120,863 |
| Australia | 109,477 |
| Netherlands | 100,310 |

---

## 4. Product Collection 

### Process
1. Filter 7 event types from MongoDB
2. Extract product_id + ip + url
3. Deduplicate by product_id
4. Extract product name from URL pattern

### Results
| Metric | Value |
|---|---|
| Records before dedup | 68,377 |
| Unique products | 19,417 |
| Products with name | 19,282 |
| Coverage | 99.3% |

---

## 5. Data Quality Verification

| Check | Expected | Actual | Status |
|---|---|---|---|
| Total events | ~41M | 41,432,473 | PASS |
| Unique IPs | ~3.2M | 3,239,628 | PASS |
| Unique products | >7,000 | 19,417 | PASS |
| Name coverage | >90% | 99.3% | PASS |
| IP errors | 0 | 0 | PASS |

---

## 6. Issues & Solutions

| Issue | Solution |
|---|---|
| Disk full (20GB) | Expanded to 100GB |
| distinct() 16MB limit | Used aggregate() + allowDiskUse=True |
| RAM overload (53%) | Batch processing + streaming |
| Crawler blocked | Extracted names from URL pattern |
| Script killed mid-run | Used nohup + incremental saving |

---

## 7. Security Notes
- MongoDB binds to 127.0.0.1 only
- Port 27017 closed to external traffic
- GCS bucket is private
- No service account keys in code
