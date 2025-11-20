data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name                   = var.name
  azs                    = local.azs
  cidr                   = var.cidr
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  enable_nat_gateway     = var.enable_nat_gateway
  tags                   = var.vpc_tags
}

resource "aws_security_group" "ec2-instance-connect-sg" {
  name        = "ec2-instance-connect-sg"
  description = "Security group for EC2 instance connect"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }
}

resource "aws_ec2_instance_connect_endpoint" "dc-ec2-connect" {
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [aws_security_group.ec2-instance-connect-sg.id]
}
