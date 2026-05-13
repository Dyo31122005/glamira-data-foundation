"""
main.py - Cloud Function to trigger BigQuery load from GCS events
Project 06: Data Pipeline & Storage

Trigger: Google Cloud Storage object.finalize event
- Detects new file uploaded to GCS bucket
- Starts BigQuery load job based on file path
- Logs results

Environment Variables (set in Cloud Function config):
    GCP_PROJECT     : GCP project ID
    DATASET_ID      : BigQuery dataset ID
"""

import os
import logging
import functions_framework
from google.cloud import bigquery

logging.basicConfig(level=logging.INFO)
log = logging.getLogger(__name__)

# ─── CONFIG FROM ENV
PROJECT_ID  = os.getenv("GCP_PROJECT", "project-5-unigap")
DATASET_ID  = os.getenv("DATASET_ID", "glamira_raw")


# Mapping: GCS path prefix → BigQuery table config
TABLE_MAPPING = {
    "raw_events/glamira_events": {
        "table": "glamira_events",
        "format": "NEWLINE_DELIMITED_JSON",
        "skip_rows": 0,
        "schema": None,  # use existing table schema
        "write_mode": "WRITE_APPEND"
    },
    "ip_location/ip_location": {
        "table": "ip_location",
        "format": "CSV",
        "skip_rows": 1,
        "schema": [
            bigquery.SchemaField("ip", "STRING"),
            bigquery.SchemaField("country_code", "STRING"),
            bigquery.SchemaField("country_name", "STRING"),
            bigquery.SchemaField("region", "STRING"),
            bigquery.SchemaField("city", "STRING"),
        ],
        "write_mode": "WRITE_TRUNCATE"
    },
    "product_react_data/": {
        "table": "product_react_data_eu",
        "format": "NEWLINE_DELIMITED_JSON",
        "skip_rows": 0,
        "schema": [
            bigquery.SchemaField("product_id", "STRING"),
            bigquery.SchemaField("source_url", "STRING"),
            bigquery.SchemaField("url_type", "STRING"),
            bigquery.SchemaField("crawled_at", "TIMESTAMP"),
            bigquery.SchemaField("http_status", "INTEGER"),
            bigquery.SchemaField("react_data", "STRING"),
        ],
        "write_mode": "WRITE_APPEND"
    },
}


def get_table_config(file_name: str):
    """Find matching table config for a GCS file path."""
    for prefix, config in TABLE_MAPPING.items():
        if file_name.startswith(prefix):
            return config
    return None


@functions_framework.cloud_event
def trigger_bigquery_load(cloud_event):
    """
    Triggered by GCS object.finalize event.
    Loads new file into BigQuery raw layer.
    """
    data = cloud_event.data
    bucket = data["bucket"]
    file_name = data["name"]
    gcs_uri = f"gs://{bucket}/{file_name}"

    log.info(f"New file detected: {gcs_uri}")

    # Skip test files and non-data files
    if any(x in file_name for x in ["test_", ".txt", "known_errors"]):
        log.info(f"Skipping non-data file: {file_name}")
        return

    # Find matching table config
    config = get_table_config(file_name)
    if not config:
        log.warning(f"No table mapping found for: {file_name}")
        return

    table_ref = f"{PROJECT_ID}.{DATASET_ID}.{config['table']}"
    log.info(f"Loading {gcs_uri} → {table_ref}")

    # Configure BigQuery load job
    client = bigquery.Client(project=PROJECT_ID)

    write_disposition = getattr(
        bigquery.WriteDisposition,
        config.get("write_mode", "WRITE_APPEND")
    )

    job_config = bigquery.LoadJobConfig(
        source_format=getattr(bigquery.SourceFormat, config["format"]),
        skip_leading_rows=config["skip_rows"],
        write_disposition=write_disposition,
        ignore_unknown_values=True,
        max_bad_records=1000,
    )

    # Use existing schema or autodetect
    if config["schema"]:
        job_config.schema = config["schema"]
    else:
        job_config.autodetect = False  # use existing table schema

    # Start load job
    load_job = client.load_table_from_uri(
        gcs_uri,
        table_ref,
        job_config=job_config
    )
    log.info(f"Load job started: {load_job.job_id}")

    # Wait for completion
    load_job.result()

    # Log results
    table = client.get_table(table_ref)
    log.info(
        f"Load complete: {gcs_uri} → {table_ref} | "
        f"Job: {load_job.job_id} | "
        f"Total rows in table: {table.num_rows:,}"
    )
