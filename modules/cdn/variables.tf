variable "cdn_bucket_name" {
  description = "Name of the S3 bucket to store images"
  type        = string
}

variable "cdn_custom_domain" {
  description = "Custom domain for the CloudFront distribution"
  type        = string
}

variable "cdn_hosted_zone" {
  description = "Name of the Hosted Zone of the domain"
  type        = string
}

variable "cdn_custom_domain_acm" {
  description = "ARN of the ACM Certificate for the custom domain"
  type        = string
}

variable "cdn_aliases" {
  description = "Additional aliases for the CloudFront distribution"
  type = list(string)
}

variable "cdn_tags" {
  description = "Tags to apply to all resources"
  type = map(string)
}

variable "cdn_price_class" {
  description = "Price class for the CloudFront distribution"
  type        = string
  default     = "PriceClass_200"
}

variable "waf_arn" {
  description = "ARN of the WAF WebACL"
  type        = string
}