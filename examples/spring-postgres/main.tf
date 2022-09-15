provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

#####################
# API setup - BEGIN #
#####################
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}
###################
# API setup - END #
###################

module "vpc_with_nat" {
  source          = "../../modules/vpc_with_nat"
  project_id      = var.project_id
  region          = var.region
  deployment_name = "spring-app-"
  depends_on      = [google_project_service.compute_api]
}

resource "google_compute_global_address" "google-managed-services-range" {
  project       = var.project_id
  name          = "google-managed-services-${module.vpc_with_nat.network_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc_with_nat.network_self_link
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  network                 = module.vpc_with_nat.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google-managed-services-range.name]
}

module "db" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version              = "12.0.0"
  name                 = "spring-app-postgres-db"
  random_instance_name = true
  database_version     = "POSTGRES_9_6"
  project_id           = var.project_id
  zone                 = var.zone
  region               = var.region
  tier                 = "db-custom-1-3840"

  deletion_protection = false

  ip_configuration = {
    ipv4_enabled        = false
    private_network     = module.vpc_with_nat.network_self_link
    require_ssl         = true
    allocated_ip_range  = null
    authorized_networks = []
  }
  depends_on = [google_project_service.sqladmin_api, google_service_networking_connection.private_service_access]
}

module "staged_binary" {
  source     = "../../modules/file_storage_bucket"
  project_id = var.project_id
  location   = var.region
  files = [
    {
      source      = var.app_location
      object_name = "app.jar"
    }
  ]
  depends_on = [google_project_service.storage_api]
}

data "template_file" "startup_script" {
  template = file("install_app.sh.tpl")
  vars = {
    STAGED_BINARY      = module.staged_binary.gs_url
    DB_USERNAME        = "default"
    DB_PASSWORD        = module.db.generated_user_password
    DB_NAME            = "default"
    DB_CONNECTION_NAME = module.db.instance_connection_name
    DB_PROJECT_ID      = var.project_id
  }
}

module "app_cluster" {
  source            = "../../modules/http_accessible_mig"
  project_id        = var.project_id
  region            = var.region
  deployment_name   = "spring-app-"
  startup_script    = data.template_file.startup_script.rendered
  health_check_path = "/getTuples"
  depends_on        = [google_project_service.compute_api, module.staged_binary, module.db]
  network           = module.vpc_with_nat.network_self_link
  subnet            = module.vpc_with_nat.subnet_self_link
}