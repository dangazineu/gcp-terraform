output "network_name" {
  value       = module.vpc.network_name
  description = "The name of the VPC being created."
}

output "network_self_link" {
  value       = module.vpc.network_self_link
  description = "The URI of the VPC being created."
}

output "subnets_names" {
  value       = module.vpc.subnets_names
  description = "The names of the subnets being created."
}

output "subnets_self_links" {
  value       = module.vpc.subnets_self_links
  description = "The self-links of subnets being created."
}

output "router" {
  value       = module.router[0].router
  description = "The created router."
}