locals {
  tags = {
    terraform   = "true"
    environment = "dev"
    project = "AppifyLab"
  }
}


module "auth-ecr" {
  source = "../../modules/ecr"

  repository_name                 = "auth-service-repo"
  repository_image_tag_mutability = "MUTABLE"
}

module "order-ecr" {
  source = "../../modules/ecr"

  repository_name                 = "order-service-repo"
  repository_image_tag_mutability = "MUTABLE"
}

module "product-ecr" {
  source = "../../modules/ecr"

  repository_name                 = "product-service-repo"
  repository_image_tag_mutability = "MUTABLE"
}

module "vpc" {
  source = "../../modules/vpc"

  region          = var.region
  name            = "al-dev-vpc"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  vpc_tags = local.tags
}

# module "cloudwatch" {
#   source = "../../modules/cloudwatch"
#
#   log_group_name    = "dc-log-group"
#   retention_in_days = 7
#   log_stream_names  = ["dc-app-log"]
#
#   tags = local.tags
# }
#
# module "alb" {
#   source = "../../modules/alb"
#
#   alb_name                   = "dc-alb"
#   vpc_id                     = module.vpc.vpc_id
#   vpc_cidr                   = module.vpc.vpc_cidr_block
#   public_subnets             = module.vpc.public_subnets
#   enable_deletion_protection = false
#
#   container_port = 8000
#
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
#
# }


# module "ecs" {
#   source  = "terraform-aws-modules/ecs/aws"
#   version = "~> 6.0"
#
#   cluster_name = "dc-cluster"
#
#   cluster_configuration = {
#     execute_command_configuration = {
#       logging = "OVERRIDE"
#       log_configuration = {
#         cloud_watch_log_group_name = module.cloudwatch.log_group_name
#       }
#     }
#   }
#
#   default_capacity_provider_strategy = {
#     FARGATE = {
#       weight = 0
#       base   = 1
#     }
#     FARGATE_SPOT = {
#       weight = 1
#     }
#   }
#
#   services = {
#     dc-app = {
#       cpu    = 1024
#       memory = 2048
#
#       subnet_ids                 = module.vpc.private_subnets
#       create_security_group      = false
#       create_task_execution_role = true
#       create_task_exec_policy    = true
#       security_group_ids         = [aws_security_group.ecs_task_sg.id]
#       enable_execute_command     = true
#
#       task_exec_iam_role_policies = {
#         ecs_exec_baseline = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
#       }
#       task_exec_ssm_param_arns = [
#         aws_ssm_parameter.api_key.arn
#       ]
#
#       container_definitions = {
#         dc-app = {
#           cpu       = 1024
#           memory    = 2048
#           essential = true
#           image     = "hashicorp/http-echo:0.2.3"
#           command = [
#             "-listen", ":8000",
#             "-text", "Hello from ECS!"
#           ]
#           portMappings = [
#             {
#               name          = "dc-app"
#               containerPort = 8000
#               protocol      = "tcp"
#             }
#           ]
#           enable_cloudwatch_logging   = true
#           create_cloudwatch_log_group = false
#           log_configuration = {
#             logDriver = "awslogs"
#             options = {
#               awslogs-group         = module.cloudwatch.log_group_name
#               awslogs-region        = var.region
#               awslogs-stream-prefix = "dc-app"
#             }
#           }
#
#           secrets = [
#             {
#               name      = "WEATHER_API_KEY"
#               valueFrom = aws_ssm_parameter.api_key.arn
#             }
#           ]
#
#           load_balancer = {
#             service = {
#               target_group_arn = module.alb.tg_arn
#               container_name   = "dc-app"
#               container_port   = 8000
#             }
#           }
#
#           tags = local.tags
#         }
#       }
#     }
#   }
# }

################################################################################
# VPC Endpoints for SSM access from private subnets
################################################################################
# Security group for VPC endpoints - ALLOWS INCOMING traffic from ECS tasks
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "al-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id
  # INGRESS rule - allow traffic FROM ECS tasks TO this endpoint
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }
  tags = {
    Name = "vpc-endpoints-sg"
  }
}

# # Security group for ECS tasks - ALLOWS OUTGOING traffic to VPC endpoints
# resource "aws_security_group" "ecs_task_sg" {
#   name        = "ecs-task-sg"
#   description = "Security group for ECS tasks"
#   vpc_id      = module.vpc.vpc_id
#   # allow ALB to reach the task port
#   ingress {
#     description     = "Service port"
#     from_port       = 8000
#     to_port         = 8000
#     protocol        = "tcp"
#     security_groups = [module.alb.security_group_id]
#   }
#   # allow tasks to talk to SSM/KMS endpoints over HTTPS
#   egress {
#     description = "Interface endpoints"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "ecs-task-sg"
#   }
# }


resource "aws_security_group" "ec2-instance-sg" {
  name        = "ec2-instance-connect-sg"
  description = "Security group for EC2 instance connect"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnet_cidr_blocks
  }
}


resource "aws_ec2_instance_connect_endpoint" "dc-ec2-connect" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.ec2-instance-sg.id]
}

