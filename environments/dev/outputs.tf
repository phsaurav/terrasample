
output "auth_repository_url" {
  description = "The URL of the Auth repository"
  value       = module.auth-ecr.repository_url
}

output "order_repository_url" {
  description = "The URL of the Order repository"
  value       = module.order-ecr.repository_url
}

output "product_repository_url" {
  description = "The URL of the Product repository"
  value       = module.product-ecr.repository_url
}

# VPC
output "vpc_id" {
  value = module.vpc.vpc_id
}
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
