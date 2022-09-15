variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "location" {
  type        = string
  description = "The GCS location."
  default     = "US"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket."
}

variable "files" {
  type = list(object({
    source      = string
    object_name = string
  }))
  description = "Files from your local client to upload to the bucket as objects."
  default     = []
}