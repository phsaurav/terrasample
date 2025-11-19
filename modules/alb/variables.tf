variable "alb_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "enable_deletion_protection" {
  type    = bool
  default = true
}

variable "security_group_ingress_rules" {
  type = map(object())
}

variable "alb_listeners" {
  type = map(object())
}

variable "container_port" {
  description = "Conainer Port for Target Group"
  type        = number
}
