data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.5.0"

  name                   = var.name
  azs                    = local.azs
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  tags                   = var.vpc_tags
}

resource "aws_ec2_instance_connect_endpoint" "dc-ec2-connect" {
  subnet_id = module.vpc.private_subnets[0]
}
