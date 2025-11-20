################################################################################
# Load Balancer
################################################################################
output "alb_arn" {
  description = "The ID and ARN of the load balancer we created"
  value       = module.alb.arn
}

output "dns_name" {
  description = "The DNS name of the load balancer"
  value       = module.alb.dns_name
}

output "tg_arn" {
  description = "ARN of the target group"
  value       = module.alb.target_groups.arn
}

output "security_group_id" {
  description = "ALB Security group id"
  value       = module.alb.security_group_id
}
