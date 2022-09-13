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
  source          = "github.com/danielgazineu/gcp-terraform//modules/vpc_with_nat"
  project_id      = var.project_id
  region          = var.region
  deployment_name = "tomcat-"
  depends_on      = [google_project_service.compute_api]
}

module "staged_binary" {
  source             = "github.com/danielgazineu/gcp-terraform//modules/binary_staging_storage_bucket"
  bucket_name_prefix = "tomcatjay-"
  project_id         = var.project_id
  region             = var.region
  file_name          = "ROOT.war"
  file_location      = var.war_filepath
  depends_on         = [google_project_service.storage_api]
}

data "template_file" "startup_script" {
  template = file("${path.module}/tomcat.sh.tpl")
  vars = {
    STAGED_BINARY = module.staged_binary.gs_url
  }
}

module "tomcat_cluster" {
  source            = "github.com/danielgazineu/gcp-terraform//modules/http_accessible_mig"
  project_id        = var.project_id
  region            = var.region
  deployment_name   = "tomcat-"
  startup_script    = data.template_file.startup_script.rendered
  depends_on        = [google_project_service.compute_api, module.staged_binary]
  health_check_path = "/healthz/"
  network           = module.vpc_with_nat.network_self_link
  subnet            = module.vpc_with_nat.subnet_self_link
}

resource "google_compute_global_address" "google-managed-services-range" {
  count         = var.create_postgres_db ? 1 : 0
  project       = var.project_id
  name          = "google-managed-services-${module.vpc_with_nat.network_name}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc_with_nat.network_self_link
}

# Creates the peering with the producer network.
resource "google_service_networking_connection" "private_service_access" {
  count                   = var.create_postgres_db ? 1 : 0
  network                 = module.vpc_with_nat.network_self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.google-managed-services-range[0].name]
}

module "db" {
  count                = var.create_postgres_db ? 1 : 0
  source               = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version              = "12.0.0"
  name                 = "tomcat-postgres-db"
  random_instance_name = true
  database_version     = "POSTGRES_14_4"
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

  additional_databases = [
    {
      name = var.database_name,
      charset = null,
      collation = null
    }
  ]

  additional_users = [
    {
      name = var.database_username,
      password = var.database_password
    }
  ]

  depends_on = [google_project_service.sqladmin_api, google_service_networking_connection.private_service_access[0]]
}

