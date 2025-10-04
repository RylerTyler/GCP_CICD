terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --------------------------
# Google Cloud Storage (data bucket)
# --------------------------
resource "google_storage_bucket" "data_bucket" {
  name     = "lbg_customer_transaction"
  location = var.region
}

# --------------------------
# BigQuery Dataset and Tables
# --------------------------
resource "google_bigquery_dataset" "analytics" {
  dataset_id = "analytics"
  location   = var.region
}

resource "google_bigquery_table" "customers" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "customers"
  schema     = file("schemas/customers_schema.json")
}

resource "google_bigquery_table" "transactions" {
  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = "transactions"
  schema     = file("schemas/transactions_schema.json")
}

# --------------------------
# Cloud Composer Environment
# --------------------------
resource "google_composer_environment" "lbg_composer" {
  name   = "lbg-composer"
  region = var.region

  config {
    node_count = 3
    software_config {
      image_version = "composer-2.6.6" # adjust to match your live version
    }
  }
}

# --------------------------
# Composer DAG (uploaded to DAG bucket)
# --------------------------
resource "google_storage_bucket_object" "dag_file" {
  name   = "dags/gcs_to_bigquery_pipeline_2.0.py"
  bucket = "europe-west2-lbg-composer-69e2495f-bucket"
  source = "dags/gcs_to_bigquery_pipeline_2.0.py"
}
