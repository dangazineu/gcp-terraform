variable "project_id" {
  type        = string
  description = "The project to deploy resources to."
}

variable "war_filepath" {
  type        = string
  description = "Where to find the war file to deploy on the local filesystem."
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

variable "create_postgres_db" {
  type        = bool
  description = "If true, creates private PostgreSQL DB on the VPC."
}

variable "database_name" {
  type        = string
  description = "Name of an extra database on the db instance."
}

variable "database_username" {
  type        = string
  description = "Username for an extra user on the database."
}

variable "database_password" {
  type        = string
  sensitive   = true
  description = "Password for an extra user on the database."
}