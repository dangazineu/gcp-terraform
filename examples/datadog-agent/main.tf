provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.${var.datadog_api_url}"
}

#####################
# API setup - BEGIN #
#####################
resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "monitoring_api" {
  service            = "monitoring.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "cloudasset_api" {
  service            = "cloudasset.googleapis.com"
  disable_on_destroy = true
}

resource "google_project_service" "iam_api" {
  service            = "iam.googleapis.com"
  disable_on_destroy = true
}
###################
# API setup - END #
###################

resource "google_service_account" "datadog_account" {
  account_id   = "datadog-connect"
  display_name = "Service Account for datadog connection"
  project = var.project_id
}

resource "google_project_iam_member" "datadog_viewer_permission" {
  role    = "roles/viewer"
  member = "serviceAccount:${google_service_account.datadog_account.email}"
  project = var.project_id
}

resource "google_service_account_key" "datadog_key" {
  service_account_id = google_service_account.datadog_account.name
}

resource "datadog_integration_gcp" "gcp_project_integration" {
  project_id     = jsondecode(base64decode(google_service_account_key.datadog_key.private_key))["project_id"]
  private_key    = jsondecode(base64decode(google_service_account_key.datadog_key.private_key))["private_key"]
  private_key_id = jsondecode(base64decode(google_service_account_key.datadog_key.private_key))["private_key_id"]
  client_email   = jsondecode(base64decode(google_service_account_key.datadog_key.private_key))["client_email"]
  client_id      = jsondecode(base64decode(google_service_account_key.datadog_key.private_key))["client_id"]

  depends_on = [
    google_project_iam_member.datadog_viewer_permission
  ]
}

resource "google_compute_instance" "datadog_agent_vm" {
  name         = "datadog-agent-vm"
  machine_type = "n1-standard-1"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }
  metadata_startup_script = "DD_API_KEY=${var.datadog_api_key} DD_SITE=\"${var.datadog_api_url}\" bash -c \"$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script_agent7.sh)\""

  service_account {
    email  = google_service_account.datadog_account.email
    scopes = ["cloud-platform"]
  }

  depends_on = [google_project_service.compute_api, google_service_account.datadog_account]
}