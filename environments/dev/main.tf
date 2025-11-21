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

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  log_group_name    = "al-task-log-group"
  retention_in_days = 7
  log_stream_names  = []

  tags = local.tags
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name = "al-alb"

  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Appifylab Task Implementation Working"
          status_code  = "200"
        }
      rules = {
        al-auth = {
          actions = [
            {
              forward = {
                target_group_key = "auth_ecs"
              }
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/auth"]
            }
          }]
        }
        al-order = {
          actions = [
            {
              forward = {
                target_group_key = "order_ecs"
              }
            }
          ]

          conditions = [{
            path_pattern = {
              values = ["/order"]
            }
          }]
        }


      }
    }
  }


  target_groups = {
    auth_ecs = {
      name                              = "al-auth-app-tg"
      backend_protocol                  = "HTTP"
      backend_port                      = var.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      vpc_id                            = module.vpc.vpc_id

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200-399"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }

      create_attachment = false
    }

        order_ecs = {
      name                              = "al-order-app-tg"
      backend_protocol                  = "HTTP"
      backend_port                      = var.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      vpc_id                            = module.vpc.vpc_id

      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200-399"
        path                = "/health"
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

  cluster_name = "al-cluster"

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
    al-auth = {
      cpu    = 1024
      memory = 2048

      subnet_ids                 = module.vpc.private_subnets
      create_security_group      = false
      create_task_execution_role = true
      create_task_exec_policy    = true
      security_group_ids         = [aws_security_group.ecs_task_sg.id]
      enable_execute_command     = true

      task_exec_iam_role_policies = {
        ecs_exec_baseline = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      }
      load_balancer = {
            service = {
              target_group_arn = "arn:aws:elasticloadbalancing:us-west-2:648539820216:targetgroup/al-auth-app-tg/adb5ec0010053f11"
              container_name   = "auth-app"
              container_port   = 8000
            }
          }

      container_definitions = {
        auth-app = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "648539820216.dkr.ecr.us-west-2.amazonaws.com/auth-service-repo:e6823d41b8218a0be5d54a6ef20ef14ef815ecbf"
          command   = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
          portMappings = [
            {
              name          = "auth-app"
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
              awslogs-stream-prefix = "al-app"
            }
          }




          tags = local.tags
        }

      }
    }

    al-order = {
      cpu    = 1024
      memory = 2048

      subnet_ids                 = module.vpc.private_subnets
      create_security_group      = false
      create_task_execution_role = true
      create_task_exec_policy    = true
      security_group_ids         = [aws_security_group.ecs_task_sg.id]
      enable_execute_command     = true

      task_exec_iam_role_policies = {
        ecs_exec_baseline = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
      }
          load_balancer = {
            service = {
              target_group_arn = module.alb.target_groups["order_ecs"].arn
              container_name   = "order-app"
              container_port   = 8000
            }
          }
      container_definitions = {
        order-app = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = "648539820216.dkr.ecr.us-west-2.amazonaws.com/order-service-repo:e6823d41b8218a0be5d54a6ef20ef14ef815ecbf"
          command   = ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
          portMappings = [
            {
              name          = "order-app"
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
              awslogs-stream-prefix = "al-app"
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

# Security group for ECS tasks - ALLOWS OUTGOING traffic to VPC endpoints
resource "aws_security_group" "ecs_task_sg" {
  name        = "ecs-task-sg"
  description = "Security group for ECS tasks"
  vpc_id      = module.vpc.vpc_id
  # allow ALB to reach the task port
  ingress {
    description     = "Service port"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    # security_groups = [module.alb.security_group_id]
  }
  # allow tasks to talk to SSM/KMS endpoints over HTTPS
  egress {
    description = "Interface endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs-task-sg"
  }
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


resource "aws_ec2_instance_connect_endpoint" "dc-ec2-connect" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.ec2-instance-sg.id]
}

