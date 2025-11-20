locals {
  tags = {
    terraform   = "true"
    environment = "dev"
  }
}
resource "aws_ssm_parameter" "api_key" {
  name        = "/dc/dev/api-key"
  description = "Weather API Key"
  type        = "SecureString"
  value       = var.weather_api_key

  tags = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name                 = "dc-ecr-repo"
  repository_image_tag_mutability = "MUTABLE"
}

module "vpc" {
  source = "../../modules/vpc"

  region          = var.region
  name            = "dc-vpc"
  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true

  vpc_tags = local.tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  log_group_name    = "dc-log-group"
  retention_in_days = 7
  log_stream_names  = ["dc-app-log"]

  tags = local.tags
}

module "alb" {
  source = "../../modules/alb"

  alb_name                   = "dc-alb"
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = module.vpc.vpc_cidr_block
  public_subnets             = module.vpc.public_subnets
  enable_deletion_protection = false

  container_port = 8000

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

}


module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 6.0"

  cluster_name = "dc-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = module.cloudwatch.log_group_name
      }
    }
  }

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 0
      base   = 1
    }
    FARGATE_SPOT = {
      weight = 1
    }
  }

  services = {
    dc-app = {
      cpu    = 1024
      memory = 2048

      subnet_ids = module.vpc.private_subnets
      container_definitions = {
        dc-app = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "${module.ecr.repository_url}:latest"
          command   = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
          portMappings = [
            {
              name          = "dc-app"
              containerPort = 8000
              protocol      = "tcp"
            }
          ]
          enable_cloudwatch_logging   = true
          create_cloudwatch_log_group = false
          log_configuration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = module.cloudwatch.log_group_name
              awslogs-region        = var.region
              awslogs-stream-prefix = "dc-app"
            }
          }

          secrets = [
            {
              name      = "WEATHER_API_KEY"
              valueFrom = aws_ssm_parameter.api_key.arn
            }
          ]

          load_balancer = {
            service = {
              target_group_arn = module.alb.tg_arn
              container_name   = "dc-app"
              container_port   = 8000
            }
          }


          security_group_ingress_rules = {
            alb_ingress = {
              description                  = "Service port"
              from_port                    = 8000
              ip_protocol                  = "tcp"
              referenced_security_group_id = module.alb.security_group_id
            }
          }
          security_group_egress_rules = {
            all = {
              ip_protocol = "-1"
              cidr_ipv4   = "0.0.0.0/0"
            }
          }
          tags = local.tags
        }
      }
    }
  }
}

################################################################################
# VPC Endpoints for SSM access from private subnets
################################################################################
# Security group for VPC endpoints - ALLOWS INCOMING traffic from ECS tasks
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "dc-vpc-endpoints-sg"
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

# Security group for ECS tasks - ALLOWS OUTGOING traffic to VPC endpoints
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id
  # EGRESS rule - allow traffic FROM ECS tasks TO VPC endpoints
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # or specifically to vpc_endpoints_sg
  }
  tags = {
    Name = "ecs-task-sg"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
}

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

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "ssmmessages-endpoint"
  }
}
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "ec2messages-endpoint"
  }
}

resource "aws_ec2_instance_connect_endpoint" "dc-ec2-connect" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.ec2-instance-sg.id]
}
