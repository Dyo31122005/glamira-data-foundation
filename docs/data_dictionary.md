# Data Dictionary — countly.summary

## General Information
| Field | Value |
|---|---|
| Database | countly |
| Collection | summary |
| Total documents | 41,432,473 |
| Time range | October — November 2019 |
| Source | Glamira e-commerce tracking |
| Stores | 85 countries |

## Fields

| Field | Type | Nullable | Description | Example |
|---|---|---|---|---|
| _id | ObjectId | No | MongoDB auto-generated ID | 5ed8cb2bc671fc36b74653ad |
| time_stamp | Number | No | Unix timestamp (seconds) | 1591266092 |
| ip | String | Yes | User IP address | 37.170.17.183 |
| user_agent | String | Yes | Browser and device info | Mozilla/5.0 (iPhone...) |
| resolution | String | Yes | Screen resolution | 375x667 |
| user_id_db | String | Yes | Glamira internal user ID | 502567 |
| device_id | String | No | Device UUID (indexed) | beb2cacb-20af-4f05-... |
| api_version | String | Yes | API version | 1.0 |
| store_id | String | No | Country store ID (85 stores) | 12 |
| local_time | String | Yes | User local datetime | 2020-06-04 12:21:27 |
| show_recommendation | String | Yes | Whether recommendation shown | false |
| current_url | String | Yes | Current page URL | https://www.glamira.fr/... |
| referrer_url | String | Yes | Previous page URL | https://www.glamira.fr/... |
| email_address | String | Yes | User email if logged in | user@example.com |
| recommendation | Boolean | Yes | Recommendation flag | false |
| utm_source | Mixed | Yes | UTM source parameter | false |
| utm_medium | Mixed | Yes | UTM medium parameter | false |
| collection | String | No | Event type name | view_product_detail |
| product_id | String | Yes | Product ID | 110474 |
| viewing_product_id | String | Yes | Viewing product ID (some events) | 110474 |
| option | Array | Yes | Product options selected | [{alloy, diamond...}] |

## Indexes
| Index | Field | Order | Purpose |
|---|---|---|---|
| _id_ | _id | - | Default MongoDB index |
| time_stamp_-1 | time_stamp | Descending | Query by time range |
| device_id_1 | device_id | Ascending | Query by user device |

## Event Types (27 total)
| Event | Count | Description |
|---|---|---|
| view_product_detail | 5,600,729 | User views a product page |
| view_listing_page | 5,592,293 | User views a category listing |
| select_product_option | 4,523,216 | User selects product option |
| select_product_option_quality | 1,135,200 | User selects quality option |
| view_static_page | 761,379 | User views static page |
| view_landing_page | 744,063 | User views landing page |
| product_detail_recommendation_visible | 671,719 | Recommendation visible on product page |
| view_home_page | 632,495 | User views home page |
| listing_page_recommendation_visible | 356,359 | Recommendation visible on listing |
| product_detail_recommendation_noticed | 256,860 | User noticed recommendation |
| view_shopping_cart | 177,337 | User views shopping cart |
| landing_page_recommendation_visible | 160,524 | Recommendation visible on landing |
| search_box_action | 124,454 | User uses search box |
| add_to_cart_action | 95,759 | User adds product to cart |
| product_detail_recommendation_clicked | 94,060 | User clicks recommendation |
| view_my_account | 59,001 | User views account page |
| checkout | 45,044 | User starts checkout |
| landing_page_recommendation_noticed | 30,504 | User noticed landing recommendation |
| listing_page_recommendation_noticed | 20,335 | User noticed listing recommendation |
| view_all_recommend | 16,574 | User views all recommendations |
| product_view_all_recommend_clicked | - | User clicks view all recommendations |
| back_to_product_action | - | User goes back to product |
| checkout_success | - | User completes purchase |
| search_box_action | - | User searches |
| sorting_relevance_click_action | - | User sorts results |
| view_sorting_relevance | - | User views sorting options |

## Derived Collections

### ip_location
| Field | Type | Description |
|---|---|---|
| ip | String | IP address |
| country_code | String | 2-letter country code |
| country_name | String | Full country name |
| region | String | Region/state |
| city | String | City name |

**Total records:** 3,239,628 unique IPs

### products (products_final_v2.csv)
| Field | Type | Description |
|---|---|---|
| product_id | String | Unique product ID |
| ip | String | IP of first recorded view |
| url | String | Product page URL |
| product_name | String | Extracted product name (nullable) |

**Total records:** 19,417 unique products  
**Name coverage:** 19,282 / 19,417 (99.3%)

## Key Statistics
| Metric | Value |
|---|---|
| Total events | 41,432,473 |
| Unique users (IPs) | 3,239,628 |
| Unique products | 19,417 |
| Unique stores | 85 |
| Top market | Germany (348,555 users) |
