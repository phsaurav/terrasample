output "waf_arn" {
  value = var.create_cdn ? aws_wafv2_web_acl.cdn_waf[0].arn : null
}