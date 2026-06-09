"""
upload_to_s3.py
---------------
Uploads Olist CSV files from a local /data directory to S3 using date-partitioned keys.

Key structure:
    raw/<table_name>/YYYY-MM-DD/<filename>.csv
    e.g.  raw/orders/2024-01-15/olist_orders_dataset.csv

Usage:
    python ingest/upload_to_s3.py

Environment variables (set in .env or shell):
    AWS_ACCESS_KEY_ID       — IAM user access key
    AWS_SECRET_ACCESS_KEY   — IAM user secret
    AWS_REGION              — e.g. us-east-1
    S3_BUCKET_NAME          — your bucket name (no s3:// prefix)
"""

import os
import sys
from datetime import date
from pathlib import Path

import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv

# ── Configuration ─────────────────────────────────────────────────────────────

load_dotenv()  # reads .env in the project root

BUCKET_NAME = os.environ["S3_BUCKET_NAME"]
AWS_REGION  = os.environ.get("AWS_REGION", "us-east-1")

# Maps local filenames → S3 prefix (table name used as folder)
OLIST_FILES = {
    "olist_orders_dataset.csv":              "orders",
    "olist_order_items_dataset.csv":         "order_items",
    "olist_order_payments_dataset.csv":      "order_payments",
    "olist_order_reviews_dataset.csv":       "order_reviews",
    "olist_customers_dataset.csv":           "customers",
    "olist_products_dataset.csv":            "products",
    "olist_sellers_dataset.csv":             "sellers",
    "olist_geolocation_dataset.csv":         "geolocation",
    "product_category_name_translation.csv": "product_categories",
}

DATA_DIR   = Path(__file__).parent.parent / "data"
DATE_STR   = date.today().isoformat()  # YYYY-MM-DD


# ── Upload logic ──────────────────────────────────────────────────────────────

def upload_file(s3_client, local_path: Path, s3_key: str) -> bool:
    """Upload a single file to S3. Returns True on success."""
    try:
        s3_client.upload_file(str(local_path), BUCKET_NAME, s3_key)
        print(f"  ✓  {local_path.name}  →  s3://{BUCKET_NAME}/{s3_key}")
        return True
    except ClientError as exc:
        print(f"  ✗  {local_path.name}  —  {exc}", file=sys.stderr)
        return False


def main() -> None:
    try:
        s3 = boto3.client("s3", region_name=AWS_REGION)
    except NoCredentialsError:
        sys.exit("ERROR: AWS credentials not found. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.")

    print(f"Uploading Olist CSVs to s3://{BUCKET_NAME}/raw/  (date partition: {DATE_STR})\n")

    success, failures = 0, 0
    for filename, table_folder in OLIST_FILES.items():
        local_path = DATA_DIR / filename
        if not local_path.exists():
            print(f"  –  {filename} not found in {DATA_DIR}, skipping.")
            continue

        s3_key = f"raw/{table_folder}/{DATE_STR}/{filename}"
        if upload_file(s3, local_path, s3_key):
            success += 1
        else:
            failures += 1

    print(f"\nDone: {success} uploaded, {failures} failed.")
    if failures:
        sys.exit(1)


if __name__ == "__main__":
    main()
