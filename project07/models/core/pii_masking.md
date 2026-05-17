# PII Data Masking

## PII Fields Identified
| Field | Table | Masking Method |
|---|---|---|
| ip | glamira_events | MD5 Hash in dim_customer |
| email_address | glamira_events | MD5 Hash in dim_customer |
| device_id | glamira_events | Used as natural key only |
| user_id_db | glamira_events | Not exposed in core/mart |

## Masking Techniques Applied
1. **MD5 Hashing** — ip and email hashed using `TO_HEX(MD5(value))`
2. **Field suppression** — raw ip/email not exposed in fact/mart tables
3. **Boolean flag** — `has_email` indicates email presence without exposing value

## Downstream Access
- `dim_customer` exposes only hashed values
- `fact_sales_order_detail` contains no PII
- Mart layer contains no PII
