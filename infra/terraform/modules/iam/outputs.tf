# IAM Module Outputs

output "alb_controller_role_arn" {
  description = "ARN of ALB controller IAM role"
  value       = aws_iam_role.alb_controller.arn
}

output "alb_controller_role_name" {
  description = "Name of ALB controller IAM role"
  value       = aws_iam_role.alb_controller.name
}

output "ecr_access_policy_arn" {
  description = "ARN of ECR access policy"
  value       = aws_iam_policy.ecr_access.arn
}
