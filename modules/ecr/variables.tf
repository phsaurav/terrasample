variable "repository_name" {
  description = "The name of the repository"
  type        = string
}

variable "repository_image_tag_mutability" {
  description = "The tag mutability setting for the repository. Must be one of: `MUTABLE`, `MUTABLE_WITH_EXCLUSION`, `IMMUTABLE`, or `IMMUTABLE_WITH_EXCLUSION`. Defaults to `IMMUTABLE`"
  type        = string
  default     = "MUTABLE"
}
