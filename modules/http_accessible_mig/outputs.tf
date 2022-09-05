output "external_ip" {
  value = module.gce-lb-http.external_ip
}

output "name" {
  value = local.mig_name
}