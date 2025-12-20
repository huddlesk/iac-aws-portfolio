output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of the VPC"
}

output "public_subnet_id" {
  value       = module.vpc.public_subnets[0]
  description = "ID of the public subnet"
}

output "private_subnet_id" {
  value       = module.vpc.private_subnets[0]
  description = "ID of the private subnet"
}
