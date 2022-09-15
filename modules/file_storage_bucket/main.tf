resource "google_storage_bucket" "bucket" {
  project                     = var.project_id
  name                        = var.bucket_name
  location                    = var.location
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "bucket_object" {
  for_each = { for f in var.files : f.object_name => f }
  name     = each.value.object_name
  source   = each.value.source
  bucket   = google_storage_bucket.bucket.name
}