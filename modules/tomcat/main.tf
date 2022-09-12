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
###################
# API setup - END #
###################

module "staged_binary" {
  source             = "../binary_staging_storage_bucket"
  bucket_name_prefix = "tomcat-"
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

module "vpc_with_nat" {
  source          = "../vpc_with_nat"
  project_id      = var.project_id
  region          = var.region
  deployment_name = "tomcat-"
  depends_on      = [google_project_service.compute_api]
}

module "tomcat_cluster" {
  source            = "../http_accessible_mig"
  project_id        = var.project_id
  region            = var.region
  deployment_name   = "tomcat-"
  startup_script    = data.template_file.startup_script.rendered
  depends_on        = [google_project_service.compute_api, module.staged_binary]
  health_check_path = "/healthz/"
  network           = module.vpc_with_nat.network_self_link
  subnet            = module.vpc_with_nat.subnet_self_link
}