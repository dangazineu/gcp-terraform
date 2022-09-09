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

variable "http_port" {
  type        = number
  description = "The http port where the application will be listening"
  default     = 8080
}

variable "app_location" {
  type        = string
  description = "The path from where the Spring Cloud GCP PostgreSQL Sample jar should be copied"
}

variable "health_check_path" {
  type    = string
  default = "/"
}