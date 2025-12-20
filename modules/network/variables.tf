variable "name" {
  type        = string
  description = "Name prefix for VPC resources"
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR for the public subnet"
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR for the private subnet"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to use"
}

variable "tags" {
  type        = map(string)
  default     = {}
}
