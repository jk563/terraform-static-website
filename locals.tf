locals {
  bucket_name = var.bucket_name == "" ? lower("${var.fqdn}-${var.hosted_zone_id}") : var.bucket_name
}
