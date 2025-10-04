from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago
from google.cloud import storage
import pandas as pd
import io

default_args = {
    'start_date': days_ago(1),
    'retries': 1,
}

# --- Validation Functions ---
def validate_customers():
    client = storage.Client()
    bucket = client.bucket("lbg_customer_transaction")
    blob = bucket.blob("raw/customers.csv")   # raw input
    data = blob.download_as_text()
    df = pd.read_csv(io.StringIO(data))

    # Basic checks
    df = df.dropna(subset=["customer_id", "email"])  # remove rows with null key fields
    df["email"] = df["email"].str.lower()
    df["signup_date"] = pd.to_datetime(df["signup_date"], errors="coerce").dt.date

    # Write cleaned file to staging
    cleaned_blob = bucket.blob("staging/customers_cleaned.csv")
    cleaned_blob.upload_from_string(df.to_csv(index=False), "text/csv")

def validate_transactions():
    client = storage.Client()
    bucket = client.bucket("lbg_customer_transaction")
    blob = bucket.blob("raw/transactions.csv")
    data = blob.download_as_text()
    df = pd.read_csv(io.StringIO(data))

    # Basic checks
    df = df.dropna(subset=["transaction_id", "customer_id", "transaction_date"])
    df["amount"] = pd.to_numeric(df["amount"], errors="coerce").fillna(0.0)
    df["currency"] = df["currency"].str.upper()
    df["transaction_date"] = pd.to_datetime(df["transaction_date"], errors="coerce")

    # Write cleaned file to staging
    cleaned_blob = bucket.blob("staging/transactions_cleaned.csv")
    cleaned_blob.upload_from_string(df.to_csv(index=False), "text/csv")

# --- DAG Definition ---
with DAG(
    'gcs_to_bigquery_pipeline_2.0',
    default_args=default_args,
    schedule_interval=None,
    catchup=False,
) as dag:

    # Step 1: Validate raw data
    validate_customers_task = PythonOperator(
        task_id="validate_customers",
        python_callable=validate_customers,
    )

    validate_transactions_task = PythonOperator(
        task_id="validate_transactions",
        python_callable=validate_transactions,
    )

    # Step 2: Load cleaned data into BigQuery
    load_customers = GCSToBigQueryOperator(
        task_id='load_customers',
        bucket='lbg_customer_transaction',
        source_objects=['staging/customers_cleaned.csv'],
        destination_project_dataset_table='lbg123-473910.analytics.customers',
        schema_fields=[
            {'name': 'customer_id', 'type': 'STRING', 'mode': 'REQUIRED'},
            {'name': 'name', 'type': 'STRING', 'mode': 'NULLABLE'},
            {'name': 'email', 'type': 'STRING', 'mode': 'NULLABLE'},
            {'name': 'signup_date', 'type': 'DATE', 'mode': 'REQUIRED'},
            {'name': 'country', 'type': 'STRING', 'mode': 'NULLABLE'}
        ],
        write_disposition='WRITE_APPEND',
        source_format='CSV',
        skip_leading_rows=1,
    )

    load_transactions = GCSToBigQueryOperator(
        task_id='load_transactions',
        bucket='lbg_customer_transaction',
        source_objects=['staging/transactions_cleaned.csv'],
        destination_project_dataset_table='lbg123-473910.analytics.transactions',
        schema_fields=[
            {'name': 'transaction_id', 'type': 'STRING', 'mode': 'REQUIRED'},
            {'name': 'customer_id', 'type': 'STRING', 'mode': 'REQUIRED'},
            {'name': 'amount', 'type': 'FLOAT', 'mode': 'NULLABLE'},
            {'name': 'currency', 'type': 'STRING', 'mode': 'NULLABLE'},
            {'name': 'transaction_date', 'type': 'DATETIME', 'mode': 'NULLABLE'},
            {'name': 'merchant', 'type': 'STRING', 'mode': 'NULLABLE'}
        ],
        write_disposition='WRITE_APPEND',
        source_format='CSV',
        skip_leading_rows=1,
    )


    validate_customers_task >> load_customers
    validate_transactions_task >> load_transactions
