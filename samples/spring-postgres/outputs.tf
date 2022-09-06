output "external_ip" {
  value = module.app_cluster.external_ip
}

output "application_url" {
  value = "http://${module.app_cluster.external_ip}/getTuples"
}

output "health_check_results" {
  value = "Wait for VMs to show as healthy in this page: https://console.cloud.google.com/compute/instanceGroups/details/${var.region}/${module.app_cluster.name}?project=${module.gcp_project.project_id}"
}

output "project_id" {
  value = module.gcp_project.project_id
}

output "binary_gs_url" {
  value = module.staged_binary.gs_url
}

output "db_instance_connection_name" {
  value       = module.db.instance_connection_name
  description = "The connection name of the master instance to be used in connection strings"
}

output "db_generated_user_password" {
  description = "The auto generated default user password if no input password was provided"
  value       = module.db.generated_user_password
  sensitive   = true
}