provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
  profile = var.profile
}

# WAF WebACL
resource "aws_wafv2_web_acl" "cdn_waf" {
  count       = var.create_cdn ? 1 : 0
  provider    = aws.us-east-1
  name        = "${var.cdn_bucket_name}-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # Rule to limit request rate
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit_value
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }


  # AWS Managed Rules - Common Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.cdn_bucket_name}-waf-main"
    sampled_requests_enabled   = true
  }
}

