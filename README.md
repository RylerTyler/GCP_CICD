Terraform GCP Workflow

This repository contains Terraform code and a GitHub Actions workflow to manage GCP resources for a data pipeline:

- Cloud Storage buckets

- BigQuery datasets and tables

- Cloud Composer environment (Composer 3)

- Deployment of Composer DAGs

The workflow automates CI/CD for infrastructure and DAG updates.

Repository Structure

GCP_CICD/
├── main.tf                  # Terraform resources
├── variables.tf             # Terraform variables
├── terraform.tfvars         # Variable values
├── schemas/                 # BigQuery table schemas
│   ├── customers_schema.json
│   └── transactions_schema.json
├── dags/                    # Composer DAGs
│   └── gcs_to_bigquery_pipeline_2.0.py
└── .github/
    └── workflows/
        └── terraform.yml    # GitHub Actions workflow

Setup

1. Clone repo:

git clone <repository-url>
cd GCP_CICD

2. Initialize Terraform:

terraform init
terraform validate
terraform fmt

3. Import existing resources (if already created, if not skip this step and go to 3.1):

terraform import google_storage_bucket.data_bucket lbg_customer_transaction
terraform import google_bigquery_dataset.analytics projects/<PROJECT_ID>/datasets/analytics
terraform import google_bigquery_table.customers projects/<PROJECT_ID>/datasets/analytics/tables/customers
terraform import google_bigquery_table.transactions projects/<PROJECT_ID>/datasets/analytics/tables/transactions
terraform import google_composer_environment.lbg_composer projects/<PROJECT_ID>/locations/<REGION>/environments/lbg-composer

3.1 Uncomment code in main.tf to create tables, buckets etc (If already created, skip this step)

4. Plan and apply

terraform plan
terraform apply -auto-approve

CI/CD Workflow

The GitHub Actions workflow (.github/workflows/terraform.yml) does the following:

Runs on push to main and on pull requests

Steps:

- Checkout code

- Install Terraform

- Authenticate to GCP using GCP_SA_KEY secret

- Run terraform init, fmt, validate, plan

- Apply changes automatically on push to main

Manages DAG uploads automatically via Terraform

Usage

- Update DAGs: Push changes to dags/ → workflow uploads DAGs.

- Update infrastructure: Modify main.tf → workflow runs plan and apply.

- Existing resources: Import them into Terraform state first to avoid recreation.

