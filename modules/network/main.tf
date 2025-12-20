terraform {
  required_version = ">= 1.14"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  

  name = var.name
  cidr = var.cidr_block
  azs = var.azs
  public_subnets = [var.public_subnet_cidr]
  private_subnets = [var.private_subnet_cidr]

  enable_nat_gateway = false
  #single_nat_gateway = true

  tags = var.tags
}