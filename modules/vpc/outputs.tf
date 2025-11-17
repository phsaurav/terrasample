################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = try(module.vpc.this[0].id, null)
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = try(module.vpc.this[0].arn, null)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = try(module.vpc.this[0].cidr_block, null)
}

################################################################################
# Subnets
################################################################################
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = compact(module.vpc.public_subnets)
}

output "private_subnets" {
  description = "A list of all private subnets"
  value       = compact(module.vpc.private_subnets)
}

output "database_subnets" {
  description = "A list of all database subnets"
  value       = compact(module.vpc.database_subnets)
}


output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.vpc.nat_ids
}
