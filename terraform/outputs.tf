output "frontend_ecr_url" {
  description = "The URL of the Frontend ECR repository"
  value       = aws_ecr_repository.app_repos["frontend"].repository_url
}

output "backend_ecr_url" {
  description = "The URL of the API/Backend ECR repository"
  value       = aws_ecr_repository.app_repos["backend"].repository_url
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "The endpoint for your EKS Kubernetes API"
  value       = aws_eks_cluster.main.endpoint
}

output "github_actions_role_arn" {
  description = "The ARN of the IAM role for GitHub Actions to assume"
  value       = aws_iam_role.github_actions_app_deployer.arn
}

output "qr_bucket_name" {
  description = "The name of the S3 bucket for QR code storage"
  value       = aws_s3_bucket.qr_codes.id
}

output "aws_region" {
  description = "The AWS region used for the deployment"
  value       = var.aws_region
}