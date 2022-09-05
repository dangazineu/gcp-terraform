variable "suffix" {
  type = string
  description = "Override this value to create unique project names and prevent clashing."
  default = ""
}

variable "project_id" {
  type = string
  description = "Set this variable so the script will use the exact project_id you define"
  default = ""
}

variable "billing_account_id" {
  type = string
  description = "The billing account ID to be associated with the project."
}

variable "folder_id" {
  type = string
  description = "The folder_id for the location where the project should be created."
}

variable "http_port" {
  type = number
  description = "The http port where the application will be listening"
  default = 8080
}

variable "app_location" {
  type = string
  description = "The path from where the Spring Cloud GCP PostgreSQL Sample jar should be copied"
}

variable "health_check_path" {
  type = string
  default = "/"
}