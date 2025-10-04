variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region for resources"
  type        = string
  default     = "europe-west2"
}
