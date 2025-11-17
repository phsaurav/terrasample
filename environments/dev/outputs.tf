output "repository_url" {
  description = "The URL of the repository"
  value       = module.ecr.repository_url
}

# VPC
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = compact(module.vpc.public_subnets)
}

output "private_subnets" {
  description = "A list of all private subnets"
  value       = compact(module.vpc.private_subnets)
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}
