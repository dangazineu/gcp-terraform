locals {
  bucket_name = "${var.bucket_name_prefix}binary-staging-storage-bucket"
}

resource "google_storage_bucket" "binary_staging_storage_bucket" {
  project = var.project_id
  name = local.bucket_name
  location = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "binary" {
  name   = var.file_name
  source = var.file_location
  bucket = local.bucket_name
  depends_on = [google_storage_bucket.binary_staging_storage_bucket]
}