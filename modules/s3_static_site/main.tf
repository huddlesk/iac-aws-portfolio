module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  

  bucket = var.bucket_name
  acl = "public-read"

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false

  tags = var.tags
}