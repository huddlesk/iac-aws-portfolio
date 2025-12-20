module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  

  name                        = var.name
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = true

  user_data = var.user_data

  tags = var.tags
}
