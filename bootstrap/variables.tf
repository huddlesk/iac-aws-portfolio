variable "bucket_name" {
  type    = string
  default = "huddlesk-tf-state-bucket"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "dynamo_table_name" {
  type    = string
  default = "terraform-state-lock"
}