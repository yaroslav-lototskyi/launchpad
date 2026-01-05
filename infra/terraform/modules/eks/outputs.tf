# EKS Module Outputs

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority" {
  description = "Certificate authority data for EKS cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID for EKS cluster"
  value       = aws_security_group.cluster.id
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the EKS cluster"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS cluster"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "node_group_ids" {
  description = "IDs of EKS node groups"
  value = {
    for k, v in aws_eks_node_group.groups : k => v.id
  }
}

output "node_group_arns" {
  description = "ARNs of EKS node groups"
  value = {
    for k, v in aws_eks_node_group.groups : k => v.arn
  }
}

output "node_group_statuses" {
  description = "Status of EKS node groups"
  value = {
    for k, v in aws_eks_node_group.groups : k => v.status
  }
}
