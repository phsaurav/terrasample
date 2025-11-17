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

  vpc_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
