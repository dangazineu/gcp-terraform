output "external_ip" {
  value = module.tomcat_cluster.external_ip
}

output "application_root_url" {
  value = "http://${module.tomcat_cluster.external_ip}"
}

output "mig_console_url" {
  value = "https://console.cloud.google.com/compute/instanceGroups/details/${var.region}/${module.tomcat_cluster.name}?project=${var.project_id}"
}