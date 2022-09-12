variable "http_port" {
  type        = number
  description = "The http port where Tomcat will be listening"
  default     = 8080
}

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

variable "startup_script" {
  type        = string
  description = "The path for a startup script to be executed by each VM as they come up"
  default     = ""
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "network" {
  type        = string
  description = "Identifier for the network to attach the mig to."
}

variable "subnet" {
  type        = string
  description = "Identifier for the network subnet to attach the mig to."
}