resource "aws_cloudwatch_log_group" "this" {
  name              = var.log_group_name
  retention_in_days = var.retention_in_days

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "this" {
  for_each = toset(var.log_stream_names)

  name           = each.value
  log_group_name = aws_cloudwatch_log_group.this.name

}
