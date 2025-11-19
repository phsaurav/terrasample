################################################################################
# Load Balancer
################################################################################
output "arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.alb.arn
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}
