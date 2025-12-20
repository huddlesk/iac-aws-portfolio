output "bucket_id" {
  value = module.s3_bucket.s3_bucket_id
}

output "website_endpoint" {
  value = module.s3_bucket.s3_bucket_website_endpoint
}
