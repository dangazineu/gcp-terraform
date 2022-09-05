output "external_ip" {
  value = module.tomcat_cluster.external_ip
}

output "application_url" {
  value = "http://${module.tomcat_cluster.external_ip}/sample"
}

output "health_check_results" {
  value = "Wait for VMs to show as healthy in this page: https://console.cloud.google.com/compute/instanceGroups/details/${local.region}/${module.tomcat_cluster.name}?project=${local.project_id}"
}

output "project_id" {
  value = google_project.gcp_project.project_id
}