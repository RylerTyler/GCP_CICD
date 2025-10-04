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
# IAM Permissions for GitHub Actions
# --------------------------
resource "google_project_iam_member" "ci_cd_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${var.github_actions_sa}"
}

resource "google_project_iam_member" "ci_cd_composer_access" {
  project = var.project_id
  role    = "roles/composer.admin"
  member  = "serviceAccount:${var.github_actions_sa}"
}

# --------------------------
# Google Cloud Storage (data bucket)
# --------------------------
# resource "google_storage_bucket" "data_bucket" {
#   name     = "lbg_customer_transaction"
#   location = var.region
# }

# --------------------------
# BigQuery Dataset and Tables
# --------------------------
# resource "google_bigquery_dataset" "analytics" {
#   dataset_id = "analytics"
#   location   = var.region
# }

# resource "google_bigquery_table" "customers" {
#   dataset_id = google_bigquery_dataset.analytics.dataset_id
#   table_id   = "customers"
#   schema     = file("schemas/customers_schema.json")
# }

# resource "google_bigquery_table" "transactions" {
#   dataset_id = google_bigquery_dataset.analytics.dataset_id
#   table_id   = "transactions"
#   schema     = file("schemas/transactions_schema.json")
# }

# --------------------------
# Cloud Composer Environment
# --------------------------
# resource "google_composer_environment" "lbg_composer" {
#   name            = "lbg-composer"
#   region          = var.region
#   service_account = "your-service-account@lbg123-473910.iam.gserviceaccount.com"

#   config {
#     software_config {
#       image_version = "composer-3-airflow-2.10.5-build.14"
#     }

#     # node_config removed — Composer 3 ignores machine_type/node_count
#   }
# }



# --------------------------
# Composer DAG (managed by Terraform)
# --------------------------
resource "google_storage_bucket_object" "dag_file" {
  name   = "dags/gcs_to_bigquery_pipeline_2.py"
  bucket = "europe-west2-lbg-composer-69e2495f-bucket"
  source = "dags/gcs_to_bigquery_pipeline_2.py"
}
