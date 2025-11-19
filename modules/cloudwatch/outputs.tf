output "log_group_name" {
  value = aws_cloudwatch_log_group.this.name
}

output "log_stream_names" {
  value = { for key, stream in aws_cloudwatch_log_stream.this : stream.name => stream.arn }
}
