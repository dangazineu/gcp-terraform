output "application_root_url" {
  value = "http://${module.tomcat_cluster.lb_external_ip}"
}

output "mig_console_url" {
  value = "https://console.cloud.google.com/compute/instanceGroups/details/${var.region}/${module.tomcat_cluster.mig_name}?project=${var.project_id}"
}