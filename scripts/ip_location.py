import IP2Location
import pymongo
import csv
import os
from datetime import datetime

# =====================
# 1. CONNECT TO MONGODB
# =====================
client = pymongo.MongoClient("mongodb://localhost:27017/")
db = client["countly"]
summary = db["summary"]
ip_location_col = db["ip_location"]

OUTPUT_CSV = "/home/g8a1_nguyenminhdat31122005/ip_location.csv"
BIN_FILE = "/home/g8a1_nguyenminhdat31122005/IP-COUNTRY-REGION-CITY.BIN"
BATCH_SIZE = 5000

# =====================
# 2. LOAD IP2LOCATION
# =====================
print("Loading IP2Location database...")
ip2loc = IP2Location.IP2Location()
ip2loc.open(BIN_FILE)

# =====================
# 3. DROP OLD DATA
# =====================
print("Dropping old data...")
ip_location_col.drop()
if os.path.exists(OUTPUT_CSV):
    os.remove(OUTPUT_CSV)

# =====================
# 4. GET UNIQUE IPs
# =====================
print("Fetching unique IPs from MongoDB...")
ip_cursor = summary.aggregate([
    { "$group": { "_id": "$ip" } },
    { "$match": { "_id": { "$ne": None } } }
], allowDiskUse=True)

# =====================
# 5. PROCESS + SAVE
# =====================
print("Processing IPs...")
batch_mongo = []
batch_csv   = []
total       = 0
errors      = 0

with open(OUTPUT_CSV, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["ip","country_code","country_name","region","city"])
    writer.writeheader()

    for doc in ip_cursor:
        ip = doc["_id"]
        try:
            rec = ip2loc.get_all(ip)
            row = {
                "ip":           ip,
                "country_code": rec.country_short,
                "country_name": rec.country_long,
                "region":       rec.region,
                "city":         rec.city,
            }
            batch_mongo.append(row)
            batch_csv.append(row)
        except:
            errors += 1

        if len(batch_mongo) >= BATCH_SIZE:
            ip_location_col.insert_many(batch_mongo, ordered=False)
            writer.writerows(batch_csv)
            total += len(batch_mongo)
            print(f"  Processed {total:,} IPs... ({errors} errors)")
            batch_mongo = []
            batch_csv   = []

    if batch_mongo:
        ip_location_col.insert_many(batch_mongo, ordered=False)
        writer.writerows(batch_csv)
        total += len(batch_mongo)

# =====================
# 6. SUMMARY
# =====================
print(f"\nCompleted!")
print(f"Total processed: {total:,} IPs")
print(f"Errors: {errors:,}")

print("\n=== Top 10 Countries ===")
pipeline = [
    { "$group": { "_id": "$country_name", "count": { "$sum": 1 } } },
    { "$sort": { "count": -1 } },
    { "$limit": 10 }
]
for r in ip_location_col.aggregate(pipeline):
    print(f"  {r['_id']}: {r['count']:,}")

client.close()
print("\nDone!")
