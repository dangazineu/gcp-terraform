terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

variable "PROJECT_ID" {
  type = string
  description = "This is the GCP PROJECT_ID used by this config"
}

variable "SERVICE_ACCOUNT_KEY_LOCATION" {
  type = string
  description = "The location of the service account key"
}

variable "SERVICE_ACCOUNT_EMAIL" {
  type = string
  description = "The full service account email"
}

provider "google" {
  credentials = file(var.SERVICE_ACCOUNT_KEY_LOCATION)
  project = var.PROJECT_ID
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"

}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "e2-standard-2"
  tags = ["terraform"]
  service_account {
    email = var.SERVICE_ACCOUNT_EMAIL
    scopes = []
  }
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {}
  }
}

resource "google_compute_firewall" "ssh-rule" {
  name = "terraform-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["terraform"]
  source_ranges = ["0.0.0.0/0"]
}