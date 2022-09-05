locals {
  hostname = "${var.deployment_name}vm"
  mig_name = "${var.deployment_name}vm-mig"
}

resource "google_compute_network" "default" {
  project = var.project_id
  name = "${var.deployment_name}network-default"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  project = var.project_id
  name = "${var.deployment_name}subnetwork-default"
  ip_cidr_range = "10.127.0.0/20"
  network = google_compute_network.default.self_link
  region = var.region
  private_ip_google_access = true
}

resource "google_compute_router" "default" {
  project = var.project_id
  name = "${var.deployment_name}router-default"
  network = google_compute_network.default.self_link
  region = var.region
}

module "cloud-nat" {
  source = "terraform-google-modules/cloud-nat/google"
  version = "1.4.0"
  router = google_compute_router.default.name
  project_id = var.project_id
  region = var.region
  name = "${var.deployment_name}cloud-nat"
}

## Allow incoming access to our instance via
## port 22, from the IAP servers
resource "google_compute_firewall" "allow-incoming-ssh-from-iap" {
  project = var.project_id
  name = "${var.deployment_name}firewall-allow-incoming-ssh-from-iap"
  network = google_compute_network.default.self_link

  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags = ["ssh-iap"]
}

module "mig_template" {
  project_id = var.project_id
  source = "terraform-google-modules/vm/google//modules/instance_template"
  version = "7.8.0"
  network = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link
  source_image_family = "debian-11"
  source_image_project = "debian-cloud"
  service_account = {
    email = ""
    scopes = ["cloud-platform"]
  }
  name_prefix = "${var.deployment_name}mig-template"
  startup_script = var.startup_script
#  data.template_file.group-startup-script.rendered

  tags = [
    module.cloud-nat.router_name,
    "ssh-iap"
  ]

}

module "mig" {
  source = "terraform-google-modules/vm/google//modules/mig"
  version = "7.8.0"
  project_id = var.project_id
  instance_template = module.mig_template.self_link
  region = var.region
  hostname = local.hostname
  mig_name = local.mig_name
  target_size = 2
  autoscaling_enabled = false
  named_ports = [
    {
      name = "http",
      port = var.http_port
    }]
  network = google_compute_network.default.self_link
  subnetwork = google_compute_subnetwork.default.self_link

  health_check = {
    type                = "http"
    initial_delay_sec   = 30
    check_interval_sec  = 30
    healthy_threshold   = 1
    timeout_sec         = 10
    unhealthy_threshold = 5
    response            = ""
    proxy_header        = "NONE"
    port                = var.http_port
    request             = ""
    request_path        = var.health_check_path
    host                = ""

  }
  update_policy = [
    {
      type                           = "PROACTIVE"
      instance_redistribution_type   = "PROACTIVE"
      minimal_action                 = "REPLACE"
      most_disruptive_allowed_action = "REPLACE"
      max_surge_fixed                = 0
      max_surge_percent              = null
      max_unavailable_fixed          = 4
      max_unavailable_percent        = null
      min_ready_sec                  = 50
      replacement_method             = "RECREATE"
    }]
}

module "gce-lb-http" {
  source = "GoogleCloudPlatform/lb-http/google"
  version = "6.3.0"
  name = "${var.deployment_name}http-lb"
  project = var.project_id
  firewall_networks = [google_compute_network.default.name]
  target_tags = [module.cloud-nat.router_name]

  backends = {
    default = {
      description = null
      protocol = "HTTP"
      port = var.http_port
      port_name = "http"
      timeout_sec = 10
      connection_draining_timeout_sec = null
      enable_cdn = false
      security_policy = null
      session_affinity = null
      affinity_cookie_ttl_sec = null
      custom_request_headers = null
      custom_response_headers = null

      health_check = {
        check_interval_sec = null
        timeout_sec = null
        healthy_threshold = null
        unhealthy_threshold = null
        request_path = var.health_check_path
        port = var.http_port
        host = null
        logging = null
      }

      log_config = {
        enable = false
        sample_rate = null
      }

      groups = [
        {
          group = module.mig.instance_group
          balancing_mode = null
          capacity_scaler = null
          description = null
          max_connections = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate = null
          max_rate_per_instance = null
          max_rate_per_endpoint = null
          max_utilization = null
        }
      ]

      iap_config = {
        enable = false
        oauth2_client_id = ""
        oauth2_client_secret = ""
      }
    }
  }
}