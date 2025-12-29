// environments/dev/variables.tf
variable "env" {
  type = string
  description = "The environemnt scope for this configuration"
  default = "prod"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources into"
  default     = "us-east-1"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 app instance (e.g., Amazon Linux 2)"
}

variable "unique_suffix" {
  type        = string
  description = "Unique suffix for globally unique resource names (e.g., S3 bucket)"
}

variable "key_name" {
  type = string
  description = "Key pair for ec2 ssh access"
}

// Network configuration
variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to use for the subnets"
  default     = ["us-east-1a"]
}

// EC2 configuration
variable "instance_type" {
  type        = string
  description = "EC2 instance type for the app server"
  default     = "t3.micro"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR range allowed to SSH into the EC2 instance"
  default     = "0.0.0.0/0" // tighten to your IP for real use
}
