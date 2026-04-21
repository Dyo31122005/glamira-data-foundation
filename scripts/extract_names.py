import pandas as pd
import os
from urllib.parse import urlparse

# =====================
# 1. READ INPUT FILE
# =====================
INPUT  = "/home/g8a1_nguyenminhdat31122005/products_to_crawl_1.csv"
OUTPUT = "/home/g8a1_nguyenminhdat31122005/products_final_v2.csv"

df = pd.read_csv(INPUT)
print(f"Total products: {len(df):,}")

# =====================
# 2. EXTRACT NAME FROM URL
# =====================
def extract_name_from_url(url):
    """
    Extract product name from Glamira URL pattern.
    Example: glamira.fr/glamira-pendant-viktor.html
          -> Glamira Pendant Viktor
    """
    try:
        path = urlparse(url).path
        name = os.path.basename(path)
        name = name.replace(".html", "").replace(".htm", "")
        name = name.replace("-", " ").strip()
        if name and len(name) > 3:
            return name.title()
    except:
        pass
    return None

# =====================
# 3. APPLY + SAVE
# =====================
df["product_name"] = df["url"].apply(extract_name_from_url)
df.to_csv(OUTPUT, index=False)

# =====================
# 4. SUMMARY
# =====================
total    = len(df)
has_name = df["product_name"].notna().sum()
no_name  = df["product_name"].isna().sum()

print(f"\nResults:")
print(f"  Total    : {total:,}")
print(f"  Has name : {has_name:,} ({has_name/total*100:.1f}%)")
print(f"  No name  : {no_name:,} ({no_name/total*100:.1f}%)")
print(f"\nSaved to: {OUTPUT}")
print(df[["product_id", "product_name", "url"]].head(10))
