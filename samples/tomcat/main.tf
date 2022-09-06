provider "google" {
  region = var.region
  zone   = var.zone
}

module "gcp_project" {
  source             = "../../modules/gcp_project"
  create_project     = var.create_project
  project_id         = var.project_id
  billing_account_id = var.billing_account_id
  folder_id          = var.folder_id
}

#####################
# API setup - BEGIN #
#####################
resource "google_project_service" "compute_api" {
  project            = module.gcp_project.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  project            = module.gcp_project.project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}
###################
# API setup - END #
###################

# Ensures the sample.war file exists locally to be uploaded to GCS
resource "null_resource" "sample-app" {
  provisioner "local-exec" {
    command = "wget -O /tmp/sample.war https://tomcat.apache.org/tomcat-7.0-doc/appdev/sample/sample.war"
  }
}
module "staged_binary" {
  source             = "../../modules/binary_staging_storage_bucket"
  project_id         = module.gcp_project.project_id
  region             = var.region
  bucket_name_prefix = module.gcp_project.project_id
  file_name          = "sample.war"
  file_location      = "/tmp/sample.war"
  depends_on         = [google_project_service.storage_api, null_resource.sample-app]
}

data "template_file" "startup_script" {
  template = file("tomcat.sh.tpl")
  vars = {
    STAGED_BINARY = module.staged_binary.gs_url
  }
}

module "tomcat_cluster" {
  source          = "../../modules/http_accessible_mig"
  project_id      = module.gcp_project.project_id
  region          = var.region
  deployment_name = "tomcat-"
  startup_script  = data.template_file.startup_script.rendered
  depends_on      = [google_project_service.compute_api]
}