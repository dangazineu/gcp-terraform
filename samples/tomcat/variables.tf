variable "create_project" {
  type        = bool
  description = "If true, creates the project and the project is managed by terraform. If false, it is assumed the project aready exists and it is not managed by terraform."
}

variable "project_id" {
  type        = string
  description = "The project to deploy resources to."
}

variable "billing_account_id" {
  type        = string
  description = "The billing account ID to be associated with the project. Required if create_project = true."
}

variable "folder_id" {
  type        = string
  description = "The folder_id for the location where the project should be created."
}

variable "region" {
  type        = string
  description = "GCP region to deploy resources to."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "GCP zone to deploy resources to. Must be a zone in the chosen region."
  default     = "us-central1-c"
}