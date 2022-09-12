module "vpc" {
  source       = "terraform-google-modules/network/google"
  project_id   = var.project_id
  network_name = "${var.deployment_name}network-default"

  subnets = [
    {
      subnet_name   = "${var.deployment_name}subnetwork-default"
      subnet_ip     = "10.127.0.0/20"
      subnet_region = var.region
    }
  ]

  firewall_rules = [
    {
      name        = "${var.deployment_name}firewall-allow-incoming-ssh-from-iap"
      direction   = "INGRESS"
      ranges      = ["35.235.240.0/20"]
      target_tags = ["ssh-iap"]
      allow = [{
        protocol = "tcp"
        ports    = ["22"]
      }]
    },
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  project = var.project_id
  name    = "${var.deployment_name}router"
  network = module.vpc.network_self_link
  region  = var.region

  nats = [{
    name = "${var.deployment_name}router-nat"
  }]
}