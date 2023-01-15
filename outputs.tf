output "bucket_name" {
  value = module.static_asset_bucket.name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.main.id
}
