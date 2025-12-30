terraform {
  backend "s3" {
    bucket = "huddlesk-tf-state-bucket"
    key = "environments/prod/terraform.tfstate"
    #dynamodb_table = "terraform-state-lock"
    use_lockfile   = true 
    region = "us-east-1"
    encrypt = true
  }
}