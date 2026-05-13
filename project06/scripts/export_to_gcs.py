"""
export_to_gcs.py - Export Glamira data from MongoDB/local files to GCS
Project 06: Data Pipeline & Storage

Usage:
    python3 export_to_gcs.py --collection events    # Export 41M events
    python3 export_to_gcs.py --collection ip        # Export IP location
    python3 export_to_gcs.py --collection products  # Export products
    python3 export_to_gcs.py --all                  # Export all
"""

import argparse
import json
import logging
import os
import time
from datetime import datetime
from pathlib import Path

from google.cloud import storage

# ─── CONFIG ───────────────────────────────────────────────────────────────────
GCS_BUCKET      = "raw_glamira_dat3112"
GCP_PROJECT     = "project-5-unigap"
MONGO_URI       = "mongodb://localhost:27017/"
MONGO_DB        = "glamira"
BATCH_SIZE      = 10000
LOG_DIR         = Path("logs")
# ──────────────────────────────────────────────────────────────────────────────

LOG_DIR.mkdir(exist_ok=True)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_DIR / "export_to_gcs.log"),
        logging.StreamHandler()
    ]
)
log = logging.getLogger(__name__)


def get_gcs_client():
    return storage.Client(project=GCP_PROJECT)


def upload_to_gcs(local_path: str, gcs_path: str):
    """Upload file to GCS."""
    client = get_gcs_client()
    bucket = client.bucket(GCS_BUCKET)
    blob = bucket.blob(gcs_path)
    
    log.info(f"Uploading {local_path} → gs://{GCS_BUCKET}/{gcs_path}")
    start = time.time()
    blob.upload_from_filename(local_path)
    elapsed = time.time() - start
    
    size = os.path.getsize(local_path) / (1024**3)
    log.info(f"Upload complete: {size:.2f}GB in {elapsed:.1f}s ({size/elapsed*1024:.1f}MB/s)")


def export_events():
    """Export 41M events from MongoDB to GCS as JSONL."""
    try:
        import pymongo
    except ImportError:
        log.error("pymongo not installed. Run: pip install pymongo")
        return

    log.info("=== Exporting glamira_events ===")
    
    client = pymongo.MongoClient(MONGO_URI)
    db = client[MONGO_DB]
    collection = db["events"]
    
    total = collection.count_documents({})
    log.info(f"Total documents: {total:,}")
    
    output_file = "/tmp/glamira_events_export.jsonl"
    count = 0
    errors = 0
    start = time.time()
    
    with open(output_file, "w") as f:
        cursor = collection.find({}, batch_size=BATCH_SIZE)
        for doc in cursor:
            try:
                # Convert ObjectId and other BSON types
                doc["_id"] = str(doc["_id"])
                f.write(json.dumps(doc, ensure_ascii=False, default=str) + "\n")
                count += 1
                if count % 1000000 == 0:
                    elapsed = time.time() - start
                    rate = count / elapsed
                    eta = (total - count) / rate / 60
                    log.info(f"Progress: {count:,}/{total:,} ({count/total*100:.1f}%) | ETA: {eta:.1f}min")
            except Exception as e:
                errors += 1
                log.warning(f"Error on doc: {e}")
    
    client.close()
    log.info(f"Export complete: {count:,} docs, {errors} errors")
    
    # Upload to GCS
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    gcs_path = f"raw_events/glamira_events_{timestamp}.jsonl"
    upload_to_gcs(output_file, gcs_path)
    os.remove(output_file)
    log.info(f"Done: gs://{GCS_BUCKET}/{gcs_path}")


def export_ip_location():
    """Export IP location CSV to GCS."""
    log.info("=== Exporting ip_location ===")
    
    # Check local file
    local_paths = [
        "/home/g8a1_nguyenminhdat31122005/project05/data/ip_location.csv",
        "~/project05/data/ip_location.csv",
        "ip_location.csv"
    ]
    
    local_file = None
    for path in local_paths:
        expanded = os.path.expanduser(path)
        if os.path.exists(expanded):
            local_file = expanded
            break
    
    if not local_file:
        log.error("ip_location.csv not found!")
        return
    
    size = os.path.getsize(local_file) / (1024**2)
    log.info(f"Found: {local_file} ({size:.1f}MB)")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    gcs_path = f"ip_location/ip_location_{timestamp}.csv"
    upload_to_gcs(local_file, gcs_path)
    log.info(f"Done: gs://{GCS_BUCKET}/{gcs_path}")


def export_products():
    """Export products CSV to GCS."""
    log.info("=== Exporting products ===")
    
    local_paths = [
        "/home/g8a1_nguyenminhdat31122005/project05/data/products_final_v2.csv",
        "~/project05/data/products_final_v2.csv",
        "products_final_v2.csv"
    ]
    
    local_file = None
    for path in local_paths:
        expanded = os.path.expanduser(path)
        if os.path.exists(expanded):
            local_file = expanded
            break
    
    if not local_file:
        log.error("products_final_v2.csv not found!")
        return
    
    size = os.path.getsize(local_file) / (1024**2)
    log.info(f"Found: {local_file} ({size:.1f}MB)")
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    gcs_path = f"products/products_final_v2_{timestamp}.csv"
    upload_to_gcs(local_file, gcs_path)
    log.info(f"Done: gs://{GCS_BUCKET}/{gcs_path}")


def main():
    parser = argparse.ArgumentParser(description="Export Glamira data to GCS")
    parser.add_argument("--collection", choices=["events", "ip", "products"],
                        help="Collection to export")
    parser.add_argument("--all", action="store_true", help="Export all collections")
    args = parser.parse_args()

    log.info("=" * 60)
    log.info("Glamira GCS Export started")
    log.info(f"Bucket: gs://{GCS_BUCKET}")
    log.info("=" * 60)

    start = time.time()

    if args.all or args.collection == "events":
        export_events()
    if args.all or args.collection == "ip":
        export_ip_location()
    if args.all or args.collection == "products":
        export_products()

    elapsed = time.time() - start
    log.info(f"\nTotal time: {elapsed/60:.1f}min")
    log.info("=" * 60)


if __name__ == "__main__":
    main()
