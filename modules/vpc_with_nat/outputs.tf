output "network_self_link" {
  value = module.vpc.network_self_link
}

output "subnet_self_link" {
  value = module.vpc.subnets_self_links[0]
}