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

module "db" {
  source               = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version              = "12.0.0"
  name                 = "postgres-db"
  random_instance_name = true
  database_version     = "POSTGRES_9_6"
  project_id           = var.project_id
  zone                 = var.zone
  region               = var.region
  tier                 = "db-custom-1-3840"

  deletion_protection = false

  ip_configuration = {
    ipv4_enabled       = true
    private_network    = null
    require_ssl        = true
    allocated_ip_range = null
    authorized_networks = [{
      name  = "sample-gcp-health-checkers-range"
      value = "130.211.0.0/28"
      }
    ]
  }
  depends_on = [google_project_service.sqladmin_api]
}

module "staged_binary" {
  source        = "../../modules/binary_staging_storage_bucket"
  project_id    = var.project_id
  region        = var.region
  file_name     = "app.jar"
  file_location = var.app_location
  depends_on    = [google_project_service.storage_api]
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
}