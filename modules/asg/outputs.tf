# * Security Group Outputs
output "alb_sg_id" {
  description = "Security group ID for Application Load Balancer"
  value       = aws_security_group.alb_sg.id
}

output "alb_sg_name" {
  description = "Security group name for Application Load Balancer"
  value       = aws_security_group.alb_sg.name
}

output "asg_sg_id" {
  description = "Security group ID for Auto Scaling Group"
  value       = aws_security_group.asg_sg.id
}

output "asg_sg_name" {
  description = "Security group name for Auto Scaling Group"
  value       = aws_security_group.asg_sg.name
}

output "ec2_rds_sg_id" {
  description = "Security group ID for EC2 RDS instance"
  value       = var.ec2_rds_sg_id
}

# * IAM Role
output "iam_role_name" {
  description = "IAM role name for the EC2 instances"
  value       = local.ec2_iam_role_name
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = local.ec2_instance_profile_name
}

#* ASG Outputs
output "asg_name" {
  description = "The name of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_name
}

output "asg_launch_template_id" {
  description = "The ID of the launch template"
  value       = module.asg.launch_template_id
}

output "asg_launch_template_arn" {
  description = "The ARN of the launch template"
  value       = module.asg.launch_template_arn
}

output "asg_launch_template_name" {
  description = "The name of the launch template"
  value       = module.asg.launch_template_name
}

output "asg_launch_template_latest_version" {
  description = "The latest version of the launch template"
  value       = module.asg.launch_template_latest_version
}

output "asg_launch_template_default_version" {
  description = "The default version of the launch template"
  value       = module.asg.launch_template_default_version
}

output "asg_autoscaling_group_id" {
  description = "The autoscaling group id"
  value       = module.asg.autoscaling_group_id
}

output "asg_autoscaling_group_name" {
  description = "The autoscaling group name"
  value       = module.asg.autoscaling_group_name
}

output "asg_autoscaling_group_arn" {
  description = "The ARN for this AutoScaling Group"
  value       = module.asg.autoscaling_group_arn
}

output "asg_autoscaling_group_min_size" {
  description = "The minimum size of the autoscale group"
  value       = module.asg.autoscaling_group_min_size
}

output "asg_autoscaling_group_max_size" {
  description = "The maximum size of the autoscale group"
  value       = module.asg.autoscaling_group_max_size
}

output "asg_autoscaling_group_desired_capacity" {
  description = "The number of Amazon EC2 instances that should be running in the group"
  value       = module.asg.autoscaling_group_desired_capacity
}

output "asg_autoscaling_group_default_cooldown" {
  description = "Time between a scaling activity and the succeeding scaling activity"
  value       = module.asg.autoscaling_group_default_cooldown
}

output "asg_autoscaling_group_health_check_grace_period" {
  description = "Time after instance comes into service before checking health"
  value       = module.asg.autoscaling_group_health_check_grace_period
}

output "asg_autoscaling_group_health_check_type" {
  description = "EC2 or ELB. Controls how health checking is done"
  value       = module.asg.autoscaling_group_health_check_type
}

output "asg_autoscaling_group_availability_zones" {
  description = "The availability zones of the autoscale group"
  value       = module.asg.autoscaling_group_availability_zones
}

output "asg_autoscaling_group_vpc_zone_identifier" {
  description = "The VPC zone identifier"
  value       = module.asg.autoscaling_group_vpc_zone_identifier
}

output "asg_autoscaling_group_load_balancers" {
  description = "The load balancer names associated with the autoscaling group"
  value       = module.asg.autoscaling_group_load_balancers
}

output "asg_autoscaling_group_target_group_arns" {
  description = "List of Target Group ARNs that apply to this AutoScaling Group"
  value       = module.asg.autoscaling_group_target_group_arns
}

# * ALB Outputs
output "alb_id" {
  description = "The ID of the Application Load Balancer"
  value       = module.alb.id
}

output "alb_arn" {
  description = "The ARN of the Application Load Balancer"
  value       = module.alb.arn
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "alb_zone_id" {
  description = "The zone_id of the Application Load Balancer"
  value       = module.alb.zone_id
}

output "http_listener_arn" {
  description = "The ARN of the HTTP load balancer listener created"
  value       = module.alb.listeners["http"].arn
}

output "target_group_names" {
  description = "Names of the target groups"
  value       = module.alb.target_groups
}

