output "project_id" {
  value = var.create_project ? google_project.gcp_project[0].project_id : var.project_id
}