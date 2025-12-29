terraform {
  backend "s3" {
    bucket = "huddlesk-tf-state-bucket"
    key = "environments/prod/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    region = "us-east-1"
    encrypt = true
  }
}