variable "http_port" {
  type        = number
  description = "The http port where your http application is listening."
  default     = 80
}

variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "regions" {
  type        = list(string)
  description = "The GCP regions to deploy migs in. At least one is required for this to work."
}

variable "mig_name" {
  type        = string
  description = "The name of the managed instance group. Other names are derived from this name."
}

variable "startup_script" {
  type        = string
  description = "A shell script to be executed by each VM as they are created."
  default     = null
}

variable "health_check_path" {
  type        = string
  description = "The path to check on your http server for 200 responses to determine if the application is running and healthy."
  default     = "/"
}

variable "source_image_family" {
  type        = string
  description = "Source disk image. If neither source_image nor source_image_family is specified, defaults to the latest public Debian image."
  default     = "debian-11"
}

variable "source_image_project" {
  type        = string
  description = "Source image family. If neither source_image nor source_image_family is specified, defaults to the latest public Debian image."
  default     = "debian-cloud"
}

variable "service_account_email" {
  type        = string
  description = "Service account to attach to the instance."
  default     = ""
}

variable "tags" {
  type        = list(string)
  description = "Network tags."
  default     = []
}

variable "autoscaling_cpu_percent" {
  type        = number
  description = "The CPU usage threshold to use to initiate a scale up or down."
  default     = 0.5
}

variable "network" {
  type        = string
  description = "Identifier for the network to attach the mig to."
}

variable "subnet" {
  type        = string
  description = "Identifier for the network subnet to attach the mig to. If not specified, will round-robin through subnets in the network."
  default     = null
}

variable "min_replicas" {
  type        = number
  description = "Number of VMs in each MIG when fully scaled down."
  default     = 1
}

variable "max_replicas" {
  type        = number
  description = "Number of VMs in each MIG when fully scaled up."
  default     = 10
}