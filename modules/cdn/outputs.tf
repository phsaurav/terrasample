output "cdn_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.cdn_bucket.id
}

output "cdn_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.cloudfront_distribution.domain_name
}

output "cdn_custom_domain" {
  description = "Custom domain for the CloudFront distribution"
  value       = var.cdn_custom_domain
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.cloudfront_distribution.arn
}
