variable "project_id" {
  type        = string
  description = "The project to deploy resources to."
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

variable "name" {
  type        = string
  description = "Prefix name to use for the deployments."
  default     = "datadog-agent"
}

variable "datadog_api_url" {
  type        = string
  description = "Datadog API URL, as described here https://registry.terraform.io/providers/DataDog/datadog/latest/docs#api_url"
  default     = "us5.datadoghq.com"
}

variable "datadog_api_key" {
  type        = string
  description = "Datadog API Key used to create resources."
  sensitive   = true
}

variable "datadog_app_key" {
  type        = string
  description = "Datadog App Key."
  sensitive   = true
}