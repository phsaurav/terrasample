# Data source for Route53 hosted zone
data "aws_route53_zone" "selected" {
  name = var.cdn_hosted_zone
}

locals {
  s3_origin_id = "S3-${var.cdn_bucket_name}"
}

# CDN S3 Bucket
resource "aws_s3_bucket" "cdn_bucket" {
  bucket = var.cdn_bucket_name
  tags   = var.cdn_tags

}

# S3 Bucket policy to allow CloudFront access
resource "aws_s3_bucket_policy" "allow_cloudfront_access" {
  bucket = aws_s3_bucket.cdn_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.cdn_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cloudfront_distribution.arn
          }
        }
      }
    ]
  })
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "cdn_acl" {
  name                              = "OAC ${var.cdn_bucket_name}"
  description                       = "Origin Access Control for S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "cloudfront_distribution" {
  origin {
    domain_name              = aws_s3_bucket.cdn_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn_acl.id
    origin_id                = local.s3_origin_id
  }

  web_acl_id = var.waf_arn

  enabled         = true
  is_ipv6_enabled = true

  aliases = var.cdn_aliases

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = var.cdn_price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    # ** The certificate needs to be in us-east-1
    acm_certificate_arn = var.cdn_custom_domain_acm
    ssl_support_method  = "sni-only"
  }
}


# Route53 record for custom domain
resource "aws_route53_record" "custom_domain" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.cdn_custom_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudfront_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}
