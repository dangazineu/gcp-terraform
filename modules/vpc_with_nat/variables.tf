variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "network_name" {
  type        = string
  description = "An optional prefix used for all resource names deployed by this module."
  default     = ""
}

variable "iap_ssh_tag" {
  type        = string
  description = "If set, will apply a firewall rule allowing IAP SSH connections to any instances with this tag."
}

variable "enable_default_firewall_rules" {
  type        = bool
  description = "Create basic firewall rules for ssh, http, https based on a tag, and internal communications between instances."
  default     = true
}

variable "router_region" {
  type        = string
  description = "Create router with nat in this region so machines without external IPs can connect to the public internet. No router is created if no region set."
  default     = null
}