output "external_ip" {
  value = module.tomcat.external_ip
}

output "application_url" {
  value = module.tomcat.application_root_url
}

output "mig_console_url" {
  value = module.tomcat.mig_console_url
}