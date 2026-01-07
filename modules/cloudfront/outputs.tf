output "distribution_id" {
  description = "The identifier for the distribution"
  value       = aws_cloudfront_distribution.cloudfront.id
}

output "distribution_arn" {
  description = "The ARN for the distribution"
  value       = aws_cloudfront_distribution.cloudfront.arn
}

output "distribution_domain_name" {
  description = "Domain name corresponding to the distribution"
  value       = aws_cloudfront_distribution.cloudfront.domain_name
}

output "distribution_status" {
  description = "The current status of the distribution"
  value       = aws_cloudfront_distribution.cloudfront.status
}

output "distribution_hosted_zone_id" {
  description = "The Cloudfront Route 53 zone ID"
  value       = aws_cloudfront_distribution.cloudfront.hosted_zone_id
}


