locals {
  common_tags = {
    Project = "terraform-aws-portfolio"
    Usage-Pattern = "Personal"
    Env     = var.env
  }
}

module "network" {
  source             = "../../modules/network"
  name               = var.env
  cidr_block         = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  private_subnet_cidr= var.private_subnet_cidr
  azs                = var.azs
  tags               = local.common_tags
}

module "security_groups" {
  source   = "../../modules/security_groups"
  name     = var.env
  vpc_id   = module.network.vpc_id
  ssh_cidr = var.ssh_cidr
  tags     = local.common_tags
}

module "ec2_app" {
  source            = "../../modules/ec2_app"
  name              = "${var.env}-app"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = module.network.public_subnet_id
  security_group_ids= [
    module.security_groups.web_sg_id,
    module.security_groups.ssh_sg_id
  ]
  #user_data = "" #file("${path.module}/user_data.sh")
  tags      = local.common_tags
}

module "s3_static_site" {
  source      = "../../modules/s3_static_site"
  bucket_name = "${var.env}-terraform-aws-portfolio-static-${var.unique_suffix}"
  tags        = local.common_tags
}

output "ec2_public_ip" {
  value = module.ec2_app.public_ip
}

output "static_site_url" {
  value = module.s3_static_site.website_endpoint
}
