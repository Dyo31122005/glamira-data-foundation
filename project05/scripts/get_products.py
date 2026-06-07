import pymongo
import pandas as pd
import os
from dotenv import load_dotenv

load_dotenv()

# =====================
# 1. CONNECT TO MONGODB
# =====================
MONGO_URI   = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
MONGO_DB    = os.getenv("MONGO_DB", "countly")
MONGO_COL   = os.getenv("MONGO_COLLECTION", "summary")
OUTPUT_PATH = os.getenv("PRODUCTS_OUTPUT_PATH", "products_to_crawl_1.csv")

client  = pymongo.MongoClient(MONGO_URI)
db      = client[MONGO_DB]
summary = db[MONGO_COL]

EVENT_COLLECTIONS = [
    "view_product_detail",
    "select_product_option",
    "select_product_option_quality",
    "add_to_cart_action",
    "product_detail_recommendation_visible",
    "product_detail_recommendation_noticed",
]

# =====================
# 2. CLEAR OLD FILE
# =====================
if os.path.exists(OUTPUT_PATH):
    os.remove(OUTPUT_PATH)
    print("Removed old file")

seen_ids    = set()
total       = 0
first_write = True

print("Fetching product data...")

# =====================
# 3. PROCESS EACH EVENT
# =====================
for event in EVENT_COLLECTIONS:
    print(f"  Processing: {event}")
    batch = []

    cursor = summary.find(
        {"collection": event},
        {
            "product_id": 1,
            "viewing_product_id": 1,
            "current_url": 1,
            "ip": 1,
            "_id": 0
        }
    ).batch_size(500)

    for doc in cursor:
        pid = doc.get("product_id") or doc.get("viewing_product_id")
        url = doc.get("current_url")
        ip  = doc.get("ip")

        if pid and url and str(pid) not in seen_ids:
            seen_ids.add(str(pid))
            batch.append({
                "product_id": str(pid),
                "ip": ip,
                "url": url
            })

        if len(batch) >= 1000:
            df = pd.DataFrame(batch)
            df.to_csv(OUTPUT_PATH, mode="a", header=first_write, index=False)
            first_write = False
            total += len(batch)
            print(f"    Saved {total:,} unique products...")
            batch = []

    if batch:
        df = pd.DataFrame(batch)
        df.to_csv(OUTPUT_PATH, mode="a", header=first_write, index=False)
        first_write = False
        total += len(batch)
        print(f"    Saved {total:,} unique products...")

# =====================
# 4. SPECIAL EVENT
# =====================
print("  Processing: product_view_all_recommend_clicked")
batch = []

cursor = summary.find(
    {"collection": "product_view_all_recommend_clicked"},
    {
        "viewing_product_id": 1,
        "referrer_url": 1,
        "ip": 1,
        "_id": 0
    }
).batch_size(500)

for doc in cursor:
    pid = doc.get("viewing_product_id")
    url = doc.get("referrer_url")
    ip  = doc.get("ip")

    if pid and url and str(pid) not in seen_ids:
        seen_ids.add(str(pid))
        batch.append({
            "product_id": str(pid),
            "ip": ip,
            "url": url
        })

if batch:
    df = pd.DataFrame(batch)
    df.to_csv(OUTPUT_PATH, mode="a", header=first_write, index=False)
    total += len(batch)

# =====================
# 5. SUMMARY
# =====================
print(f"\nCompleted! Total unique products: {total:,}")
print(f"Saved to: {OUTPUT_PATH}")

df_check = pd.read_csv(OUTPUT_PATH)
print(f"Verification: {len(df_check):,} rows in file")
print(df_check.head())

client.close()
