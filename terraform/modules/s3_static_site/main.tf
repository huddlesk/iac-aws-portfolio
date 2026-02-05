module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"
  

  bucket = var.bucket_name
#  acl = "public-read"

  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false

  force_destroy = true

  tags = var.tags
}

resource "aws_s3_bucket_ownership_controls" "owner_enforcement" {
  bucket = module.s3_bucket.s3_bucket_id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
