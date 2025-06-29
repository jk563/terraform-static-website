module "static_asset_bucket" {
  source = "git@github.com:jk563/terraform-private-s3-bucket"

  bucket_name = local.bucket_name
  force_destroy = var.force_destroy
}

module "subdomain_cert" {
  providers = {
    aws = aws.us-east-1
  }

  source = "git@github.com:jk563/terraform-acm-certificate"

  fqdn           = var.fqdn
}

data "aws_route53_zone" "parent" {
  name = local.parent_zone
}

resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = module.static_asset_bucket.regional_domain_name
    origin_id                = "S3-${module.static_asset_bucket.name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # Conditional API Gateway origin
  dynamic "origin" {
    for_each = var.api_gateway_origin_domain != "" ? [1] : []
    content {
      domain_name = var.api_gateway_origin_domain
      origin_id   = "APIGateway"
      
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  # By default, show index.html file
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  aliases             = [var.fqdn]

  default_cache_behavior {
    compress = true

    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${module.static_asset_bucket.name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
  }

  # API Gateway cache behavior for /api/* paths
  dynamic "ordered_cache_behavior" {
    for_each = var.api_gateway_origin_domain != "" ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD"]
      target_origin_id = "APIGateway"
      compress         = true

      forwarded_values {
        query_string = true
        headers      = ["*"]
        cookies {
          forward = "all"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
    }
  }

  # Distributes content to US and Europe
  price_class = "PriceClass_100"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL certificate for the service.
  viewer_certificate {
    acm_certificate_arn = module.subdomain_cert.certificate_arn
    ssl_support_method  = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${local.bucket_name}-oac"
  description                       = "S3 OAC"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = module.static_asset_bucket.name
  policy = data.aws_iam_policy_document.allow_cloudfront.json
}

data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.static_asset_bucket.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.main.arn]
    }
  }
}

resource "aws_route53_record" "main" {
  zone_id = data.aws_route53_zone.parent.id
  name    = var.fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.main.domain_name
    zone_id                = aws_cloudfront_distribution.main.hosted_zone_id
    evaluate_target_health = false
  }
}
