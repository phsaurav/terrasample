# CDN WAF Variables
variable "create_cdn" {
  description = "Whether to create the CDN resources"
  type        = bool
  default     = true
}

variable "cdn_bucket_name" {
  description = "Name of the S3 bucket to store images"
  type        = string
}

variable "waf_rate_limit_value" {
  description = "WAF Rate Limit Value for request within 5 minute"
  type        = number
}

variable "profile" {
  description = "AWS profile to use"
  type        = string
}