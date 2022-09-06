variable "create_project" {
  type = bool
  description = "If true, creates the project and the project is managed by terraform. If false, it is assumed the project aready exists and it is not managed by terraform."
  default = false
}

variable "project_id" {
  type = string
  description = "The project to set up."
}

variable "billing_account_id" {
  type = string
  description = "The billing account ID to be associated with the project."
}

variable "folder_id" {
  type = string
  description = "The folder_id for the location where the project should be created."
}