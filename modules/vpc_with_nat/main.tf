module "vpc" {
  source = "terraform-google-modules/network/google"

  project_id   = var.project_id
  network_name = var.network_name

  auto_create_subnetworks = true
  subnets                 = []

  firewall_rules = var.iap_ssh_tag != null ? [
    {
      name        = "${var.network_name}-firewall-allow-incoming-ssh-from-iap"
      direction   = "INGRESS"
      ranges      = ["35.235.240.0/20"]
      target_tags = ["ssh-iap"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
  ] : []
}

module "net-firewall" {
  source = "terraform-google-modules/network/google//modules/fabric-net-firewall"
  count  = var.enable_default_firewall_rules ? 1 : 0

  project_id = var.project_id
  network    = module.vpc.network_name

  internal_ranges_enabled = true
  internal_allow = [
    {
      "protocol" : "tcp"
    }
  ]
}

module "router" {
  source = "terraform-google-modules/cloud-router/google"
  count  = var.router_region != null ? 1 : 0

  project = var.project_id
  name    = "${var.network_name}-router"
  network = module.vpc.network_self_link
  region  = var.router_region

  nats = [{
    name = "${var.network_name}-router-nat"
  }]
}