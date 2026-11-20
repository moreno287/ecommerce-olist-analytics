"""Download the Olist Brazilian E-Commerce dataset into ./data.

Source: Olist's public repository (https://github.com/olist/work-at-olist-data),
licensed CC BY-NC-SA 4.0. The large geolocation file is not needed and is skipped.
"""
from pathlib import Path
from urllib.request import urlretrieve

BASE = "https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/"
FILES = [
    "olist_customers_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]

data = Path(__file__).parent / "data"
data.mkdir(exist_ok=True)
for name in FILES:
    target = data / name
    if target.exists():
        print(f"ok      {name}")
        continue
    print(f"get     {name}")
    urlretrieve(BASE + name, target)
print("Done.")
