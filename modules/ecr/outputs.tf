################################################################################
# Repository (Public and Private)
################################################################################

output "repository_name" {
  description = "Name of the repository"
  value       = aws_ecr_repository.dc-ecr-repo.name
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.dc-ecr-repo.arn
}

output "repository_registry_id" {
  description = "The registry ID where the repository was created"
  value       = aws_ecr_repository.dc-ecr-repo.id
}

output "repository_url" {
  description = "The URL of the repository"
  value       = aws_ecr_repository.dc-ecr-repo.repository_url
}
