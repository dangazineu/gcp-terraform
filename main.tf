terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

variable "SUFFIX" {
  type = string
  description = "Override this value to create unique project names and prevent clashing."
  default = ""
}

variable "BILLING_ACCOUNT" {
  type = string
  description = "The billing account ID to be associated with the project."
}

variable "FOLDER_ID" {
  type = string
  description = "The folder_id for the location where the project should be created."
}

provider "google" {
  region  = "us-central1"
  zone    = "us-central1-c"
}

data "google_billing_account" "acct" {
  billing_account = var.BILLING_ACCOUNT
  open = true
}

resource "google_project" "gcp_project" {
  name       = "terraform-project${var.SUFFIX}"
  project_id = "terraform-project${var.SUFFIX}"
  folder_id = var.FOLDER_ID
  billing_account = data.google_billing_account.acct.id
  auto_create_network = false
}

resource "google_project_service" "compute_api" {
  project = google_project.gcp_project.project_id
  service = "compute.googleapis.com"
  disable_dependent_services = true
  depends_on = [google_project.gcp_project]
}

resource "google_compute_network" "vpc_network" {
  project = google_project.gcp_project.project_id
  name = "terraform-network"
  depends_on = [google_project_service.compute_api]
}

resource "google_compute_instance" "vm_instance" {
  project = google_project.gcp_project.project_id
  name         = "terraform-instance"
  machine_type = "e2-standard-2"
  tags = ["terraform"]
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }

  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_firewall" "ssh-rule" {
  project = google_project.gcp_project.project_id
  name = "terraform-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["terraform"]
  source_ranges = ["0.0.0.0/0"]
  depends_on = [google_compute_instance.vm_instance]
}