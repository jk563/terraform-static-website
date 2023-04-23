locals {
  parent_zone = join(".", slice(split(".", var.fqdn), 1, length(split(".", var.fqdn))))
  bucket_name = var.bucket_name == "" ? lower("${var.fqdn}-assets") : var.bucket_name
}

