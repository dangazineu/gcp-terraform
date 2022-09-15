output "objects" {
  value = google_storage_bucket_object.bucket_object[*]
}

output "gs_urls" {
  value = [
    for o in google_storage_bucket_object.bucket_object : "${google_storage_bucket.bucket.url}/${o.name}"
  ]
}