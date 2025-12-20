variable "name"    { type = string }
variable "vpc_id"  { type = string }
variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH into EC2"
}
variable "tags" {
  type    = map(string)
  default = {}
}