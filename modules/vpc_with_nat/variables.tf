variable "project_id" {
  type        = string
  description = "The GCP project ID"
}

variable "region" {
  type = string
}

variable "deployment_name" {
  type        = string
  description = "An optional prefix used for all resource names deployed by this module"
  default     = ""
}