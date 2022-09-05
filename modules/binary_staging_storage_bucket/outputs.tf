output "self_link" {
  value = google_storage_bucket_object.binary.self_link
}

output "media_link" {
  value = google_storage_bucket_object.binary.media_link
}

output "crc32c" {
  value = google_storage_bucket_object.binary.crc32c
}

output "md5hash" {
  value = google_storage_bucket_object.binary.md5hash
}

output "gs_url" {
  value = "${google_storage_bucket.binary_staging_storage_bucket.url}/${var.file_name}"
}