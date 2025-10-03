resource "google_storage_bucket" "my_bucket" {
  name                     = "github-action-gcs123"
  location                 = "EU"
  force_destroy            = true
  public_access_prevention = true
}