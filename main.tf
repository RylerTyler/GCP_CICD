provider "google" {
  project = "lbg123-473910"
  region  = "europe-west2"
}

resource "google_storage_bucket" "my_bucket" {
  name                     = "github-action-gcs123_new"
  location                 = "EU"
  force_destroy            = true
  public_access_prevention = "enforced"
}