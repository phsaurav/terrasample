variable "enabled" {
  description = "Weather the distribution is enabled"
  type        = bool
  default     = true
}

variable "comment" {
  description = "Any comment about the distribution"
  type        = string
  default     = ""
}

variable "aliases" {
  description = "List of CNAME aliases for the distribution"
  type        = list(string)
  default     = []
}

variable "price_class" {
  description = "Cloudfront price class"
  type        = string
  default     = "PriceClass_200"
}

variable "web_acl_id" {
  description = "The identifier for the WAF"
  type        = string
  default     = null
}

# Origin Access Control related variables
variable "create_oac" {
  description = "Wheter to create Origin Access Control"
  type        = bool
  default     = false
}

variable "oac_name" {
  description = "Description for the Origin Access Control"
  type        = string
  default     = "oac"
}

variable "oac_description" {
  description = "Description for the Origin Access Control"
  type        = string
  default     = "Origin Access Control"
}

variable "oac_origin_type" {
  description = "Origin type for the Origin Access Control"
  type        = string
  default     = "s3"
}

variable "oac_signing_behavior" {
  description = "Signing behavior for the Origin Access Control"
  type        = string
  default     = "always"
}

variable "oac_signing_protocol" {
  description = "Signing protocol for the Origin Access Control"
  type        = string
  default     = "sigv4"
}

variable "external_oac_id" {
  description = "External Origin Access Control ID to use if create_oac is false"
  type        = string
  default     = null
}

# Origin related variables
variable "origins" {
  description = "List of origins for the Cloudfront distribution"
  type = list(object({
    domain_name = string
    origin_id   = string
    use_oac     = optional(bool, false)
    custom_origin_config = optional(object({
      http_port              = optional(number, 80)
      https_port             = optional(number, 443)
      origin_protocol_policy = string
      origin_ssl_protocols   = optional(list(string), ["TLSv1.2"])
    }))
  }))
}

variable "origin_groups" {
  description = "List of origin groups for failover"
  type = list(object({
    origin_id             = string
    failover_status_codes = list(number)
    members = list(object({
      origin_id = string
    }))
  }))
  default = []
}

# Cache behavior related variables
variable "ordered_cache_behavior" {
  description = "Path based cache behaviors"
  type = list(object({
    path_pattern               = string
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    viewer_protocol_policy     = string
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 86400)
    max_ttl                    = optional(number, 31536000)
    forwarded_values = optional(object({
      query_string = bool
      headers      = optional(list(string))
      cookies = object({
        forward           = string
        whitelisted_names = optional(list(string))
      })
    }))
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  }))
  default = []
}

variable "default_cache_behavior" {
  description = "Default cache behavior"
  type = object({
    allowed_methods            = list(string)
    cached_methods             = list(string)
    target_origin_id           = string
    viewer_protocol_policy     = string
    cache_policy_id            = optional(string)
    origin_request_policy_id   = optional(string)
    response_headers_policy_id = optional(string)
    min_ttl                    = optional(number, 0)
    default_ttl                = optional(number, 86400)
    max_ttl                    = optional(number, 31536000)
    forwarded_values = optional(object({
      query_string = bool
      headers      = optional(list(string))
      cookies = object({
        forward           = string
        whitelisted_names = optional(list(string))
      })
    }))
    function_associations = optional(list(object({
      event_type   = string
      function_arn = string
    })), [])
  })
}

variable "custom_error_responses" {
  description = "Custom error responses for the Cloudfront distribution"
  type = list(object({
    error_code            = number
    response_code         = optional(number)
    response_page_path    = optional(string)
    error_caching_min_ttl = optional(number, 10)
  }))
  default = []
}

variable "geo_restriction" {
  description = "Geographic restriction configuration"
  type = object({
    restriction_type = string
    locations        = optional(list(string), [])
  })
  default = {
    restriction_type = "none"
  }
}

variable "viewer_certificate" {
  description = "Viewer certificate configuration"
  type = object({
    acm_certificate_arn            = optional(string)
    cloudfront_default_certificate = optional(bool, false)
    ssl_support_method             = optional(string, "sni-only")
    minimum_protocol_version       = optional(string, "TLSv1.2_2021")
  })
  default = {
    cloudfront_default_certificate = true
  }
}

variable "cdn_tags" {
  description = "Tags to apply to autoscaling group"
  type        = map(string)
}
