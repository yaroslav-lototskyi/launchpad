# ECR Module Outputs

output "repository_urls" {
  description = "URLs of ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.arn
  }
}

output "repository_ids" {
  description = "Registry IDs of ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.registry_id
  }
}
