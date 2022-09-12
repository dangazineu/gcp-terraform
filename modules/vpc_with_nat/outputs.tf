output "network_self_link" {
  value = module.vpc.network_self_link
}

output "network_name" {
  value = module.vpc.network_name
}

output "subnet_self_link" {
  value = module.vpc.subnets_self_links[0]
}