variable "log_group_name" {
  type        = string
  description = "Log Group Name"
}

variable "retention_in_days" {
  type        = number
  description = "Log retention days"
}

variable "tags" {
  type = map(string)
}

variable "log_stream_names" {
  type        = set(string)
  description = "List of log streams"
}
