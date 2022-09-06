data "google_billing_account" "acct" {
  count = var.create_project ? 1 : 0
  billing_account = var.billing_account_id
  open = true
}

resource "google_project" "gcp_project" {
  count = var.create_project ? 1 : 0
  name       = var.project_id
  project_id = var.project_id
  folder_id = var.folder_id
  billing_account = data.google_billing_account.acct[count.index].id
  auto_create_network = false
  skip_delete = true
}