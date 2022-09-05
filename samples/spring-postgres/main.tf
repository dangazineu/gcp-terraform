locals {
  project_id = var.project_id != "" ? var.project_id : "sample-spring-postgres${var.suffix}"
  region  = "us-central1"
  zone    = "us-central1-c"
}

provider "google" {
  region = local.region
  zone = local.zone
}

data "google_billing_account" "acct" {
  billing_account = var.billing_account_id
  open = true
}

resource "google_project" "gcp_project" {
  name       = local.project_id
  project_id = local.project_id
  folder_id = var.folder_id
  billing_account = data.google_billing_account.acct.id
  auto_create_network = false

  # This project won't be deleted when you run `terraform destroy`
  # To be able to reuse an existing project, run the following command before you run `terraform apply`
  # $ terraform import google_project.gcp_project {YOUR_PROJECT_ID}
  skip_delete = true
}

#####################
# API setup - BEGIN #
#####################
resource "google_project_service" "compute_api" {
  project = google_project.gcp_project.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project.gcp_project]
}

resource "google_project_service" "storage_api" {
  project = google_project.gcp_project.project_id
  service = "storage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin_api" {
  project = google_project.gcp_project.project_id
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
  depends_on = [google_project.gcp_project]
}
###################
# API setup - END #
###################

module "db" {
  source  = "GoogleCloudPlatform/sql-db/google//modules/postgresql"
  version = "12.0.0"
  name                 = "postgres-db"
  random_instance_name = true
  database_version     = "POSTGRES_9_6"
  project_id           = google_project.gcp_project.project_id
  zone                 = local.zone
  region               = local.region
  tier                 = "db-custom-1-3840"

  deletion_protection = false

  ip_configuration = {
    ipv4_enabled        = true
    private_network     = null
    require_ssl         = true
    allocated_ip_range  = null
    authorized_networks = [{
      name  = "sample-gcp-health-checkers-range"
      value = "130.211.0.0/28"
    }
    ]
  }
  depends_on = [google_project_service.sqladmin_api]
}

module "staged_binary" {
  source = "../../modules/binary_staging_storage_bucket"
  project_id = google_project.gcp_project.project_id
  region = local.region
  bucket_name_prefix = google_project.gcp_project.project_id
  file_name = "app.jar"
  file_location = var.app_location
  depends_on = [google_project_service.storage_api]
}

data "template_file" "startup_script" {
  template = file("install_app.sh.tpl")
  vars = {
    STAGED_BINARY = module.staged_binary.gs_url
    DB_USERNAME = "default"
    DB_PASSWORD = module.db.generated_user_password
    DB_NAME = "default"
    DB_CONNECTION_NAME = module.db.instance_connection_name
    DB_PROJECT_ID = google_project.gcp_project.project_id
  }
}

module "app_cluster" {
  source = "../../modules/http_accessible_mig"
  project_id = google_project.gcp_project.project_id
  region = local.region
  deployment_name = "spring-app-"
  startup_script = data.template_file.startup_script.rendered
  health_check_path = "/getTuples"
  depends_on = [google_project_service.compute_api, module.staged_binary, module.db]
}