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

  alb_listeners = {
    ex_ecs = {
      backend_protocol                  = "HTTP"
      backend_port                      = 8000
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 30
        matcher             = "200"
        path                = "/"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
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

      container_definitions = {
        dc-app = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "${module.ecr.repository_url}:latest"
          portMappings = [
            {
              name          = "dc-app"
              containerPort = 8000
              protocol      = "tcp"
            }
          ]
          enable_cloudwatch_logging   = true
          create_cloudwatch_log_group = false
          cloud_watch_log_group_name  = module.cloudwatch.log_group_name

          secrets = [
            {
              name      = "WEATHER_API_KEY"
              valueFrom = "arn:aws:ssm:us-west-2:648539820216:parameter/dhaka-celsius/weather-api-key"
            }
          ]

          load_balancer = {
            service = {
              target_group_arn = module.alb.tg_arn
              container_name   = "dc-app"
              container_port   = 8000
            }
          }
          subnet_ids = module.vpc.private_subnets

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
