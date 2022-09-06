output "external_ip" {
  value = module.tomcat_cluster.external_ip
}

output "application_root_url" {
  value = "http://${module.tomcat_cluster.external_ip}"
}

output "health_check_results" {
  value = "Wait for VMs to show as healthy in this page: https://console.cloud.google.com/compute/instanceGroups/details/${var.region}/${module.tomcat_cluster.name}?project=${var.project_id}"
}