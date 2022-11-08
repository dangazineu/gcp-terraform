output "instance_template_self_link" {
  value = module.mig_template.self_link
}

output "instance_template_name" {
  value = module.mig_template.name
}

output "mig_self_links" {
  value = [
    for mig in module.mig : mig.self_link
  ]
}

output "mig_name" {
  value = var.mig_name
}

output "lb_external_ip" {
  value = module.http_lb.external_ip
}