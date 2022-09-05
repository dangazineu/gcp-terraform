locals {
  project_id = var.project_id != "" ? var.project_id : "sample-tomcat${var.suffix}"
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
  # $ terraform import google_project.gcp_project "sample-tomcat$TF_VAR_suffix
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
  source = "../../modules/binary_staging_storage_bucket"
  project_id = google_project.gcp_project.project_id
  region = local.region
  bucket_name_prefix = google_project.gcp_project.project_id
  file_name = "sample.war"
  file_location = "/tmp/sample.war"
  depends_on = [google_project_service.storage_api, null_resource.sample-app]
}

data "template_file" "startup_script" {
  template = file("tomcat.sh.tpl")
  vars = {
    STAGED_BINARY = module.staged_binary.gs_url
  }
}

module "tomcat_cluster" {
  source = "../../modules/http_accessible_mig"
  project_id = local.project_id
  region = local.region
  deployment_name = "tomcat-"
  startup_script = data.template_file.startup_script.rendered
  depends_on = [google_project_service.compute_api]
}