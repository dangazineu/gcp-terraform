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

variable "snowflake_username" {
  type        = string
  description = "Snowflake instance username."
}

variable "snowflake_password" {
  type        = string
  description = "Snowflake instance password."
  sensitive   = true
}

variable "snowflake_account_locator" {
  type        = string
  description = "Snowflake account locator. Can be found in the URL of your snowflake UX."
}

variable "snowflake_region" {
  type        = string
  description = "Snowflake instance region. Can be found in the URL of your snowflake UX. For example, 'us-east4.gcp'."
}

variable "name" {
  type        = string
  description = "Prefix name to use for the deployments."
  default     = "snowflake"
}