module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 10.0"

  name = var.alb_name

  load_balancer_type = "application"

  vpc_id  = var.vpc_id
  subnets = var.public_subnets

  enable_deletion_protection = var.enable_deletion_protection

  security_group_ingress_rules = var.security_group_ingress_rules

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "ex_ecs"
      }
    }
  }


  target_groups = {
    ex_ecs = {
      name                              = "dc-app-tg"
      backend_protocol                  = "HTTP"
      backend_port                      = var.container_port
      target_type                       = "ip"
      deregistration_delay              = 5
      load_balancing_cross_zone_enabled = true
      vpc_id                            = var.vpc_id

      health_check = {
        enabled             = true
        healthy_threshold   = 5
        interval            = 180
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
