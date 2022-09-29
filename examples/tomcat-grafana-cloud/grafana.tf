terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "1.29.0"
    }
  }
}

provider "grafana" {
  alias         = "cloud"
  cloud_api_key = var.grafana_cloud_api_key
}

provider "grafana" {
  alias = "stack"
  url   = grafana_cloud_stack.stack.url
  auth  = grafana_api_key.stack_api_key.key
}

resource "google_service_account" "grafana_account" {
  account_id = "${var.name}-grafana"
}

resource "google_service_account_key" "grafana_key" {
  service_account_id = google_service_account.grafana_account.name
}

resource "google_project_iam_member" "grafana_account_permission" {
  project = google_service_account.grafana_account.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.grafana_account.email}"
}

resource "grafana_cloud_stack" "stack" {
  provider    = grafana.cloud
  name        = "${var.name}.grafana.net"
  slug        = var.name
  region_slug = "us"
}

resource "grafana_api_key" "stack_api_key" {
  provider         = grafana.cloud
  cloud_stack_slug = grafana_cloud_stack.stack.slug
  name             = "terraform"
  role             = "Admin"
}

resource "grafana_cloud_api_key" "metrics_api_key" {
  provider       = grafana.cloud
  cloud_org_slug = grafana_cloud_stack.stack.org_slug
  name           = "terraform-metrics"
  role           = "MetricsPublisher"
}

resource "grafana_data_source" "gcp_monitoring_data" {
  provider = grafana.stack
  type     = "stackdriver"
  name     = "gcp_monitoring_data"

  json_data_encoded = jsonencode({
    "tokenUri"           = "https://oauth2.googleapis.com/token"
    "authenticationType" = "jwt"
    "defaultProject"     = google_service_account.grafana_account.project
    "clientEmail"        = google_service_account.grafana_account.email
  })

  secure_json_data_encoded = jsonencode({
    "privateKey" = jsondecode(base64decode(google_service_account_key.grafana_key.private_key))["private_key"]
  })

  depends_on = [google_project_iam_member.grafana_account_permission]
}