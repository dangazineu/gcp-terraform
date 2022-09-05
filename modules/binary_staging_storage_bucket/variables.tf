variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type = string
}

variable "bucket_name_prefix" {
  type = string
  description = "An optional prefix used for all resource names deployed by this module"
  default = ""
}

variable "file_name" {
  type = string
}

variable "file_location" {
  type = string
}