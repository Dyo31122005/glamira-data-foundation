import pandas as pd
import requests
from bs4 import BeautifulSoup
import time
import os
import random

# =====================
# 1. CONFIGURATION
# =====================
INPUT_FILE  = "/home/g8a1_nguyenminhdat31122005/products_to_crawl_1.csv"
OUTPUT_FILE = "/home/g8a1_nguyenminhdat31122005/products_final.csv"

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/121.0",
]

# =====================
# 2. READ INPUT
# =====================
df = pd.read_csv(INPUT_FILE)
print(f"Total products to crawl: {len(df):,}")

# =====================
# 3. RESUME IF PARTIAL
# =====================
if os.path.exists(OUTPUT_FILE):
    done_df  = pd.read_csv(OUTPUT_FILE)
    done_ids = set(done_df["product_id"].astype(str))
    print(f"Already crawled: {len(done_ids):,} products")
else:
    done_ids = set()

# =====================
# 4. CRAWL FUNCTION
# =====================
def get_product_name(url):
    """
    Crawl product name from Glamira product page.
    Returns product name string or None if failed.
    """
    try:
        headers = {"User-Agent": random.choice(USER_AGENTS)}
        res = requests.get(url, headers=headers, timeout=10)
        if res.status_code == 200:
            soup = BeautifulSoup(res.text, "html.parser")
            h1 = soup.find("h1")
            if h1:
                return h1.get_text(strip=True)
            title = soup.find("title")
            if title:
                return title.get_text(strip=True).split("|")[0].strip()
    except Exception:
        pass
    return None

# =====================
# 5. CRAWL EACH PRODUCT
# =====================
results = []
errors  = 0

for i, row in df.iterrows():
    pid = str(row["product_id"])

    if pid in done_ids:
        continue

    name = get_product_name(row["url"])
    results.append({
        "product_id":   pid,
        "product_name": name,
        "ip":           row.get("ip"),
        "url":          row["url"]
    })

    if name:
        print(f"[{i+1}/{len(df)}] {pid}: {name}")
    else:
        errors += 1

    # Save every 100 products
    if len(results) % 100 == 0:
        pd.DataFrame(results).to_csv(
            OUTPUT_FILE, mode="a",
            header=not os.path.exists(OUTPUT_FILE),
            index=False
        )
        results = []

    # Random delay to avoid blocking
    time.sleep(random.uniform(1, 3))

# Save remaining
if results:
    pd.DataFrame(results).to_csv(
        OUTPUT_FILE, mode="a",
        header=not os.path.exists(OUTPUT_FILE),
        index=False
    )

# =====================
# 6. SUMMARY
# =====================
print(f"\nCompleted!")
print(f"Errors: {errors:,}")
print(f"Results saved to: {OUTPUT_FILE}")
