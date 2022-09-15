output "external_ip" {
  value = module.http_lb.external_ip
}

output "name" {
  value = local.mig_name
}