output "region" {
  value       = var.region
  description = "The AWS region to deploy the EKS cluster."
}

output "cluster_name" {
  value       = var.cluster_name
  description = "The name of the EKS cluster."
}

output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "The unique identifier for the EKS cluster."
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
  description = "The desired Kubernetes version for creating the EKS cluster."
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "The endpoint for your EKS Kubernetes API server"
  sensitive   = true
}

output "cluster_ca_certificate" {
  value       = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  description = "The certificate for your EKS Kubernetes API server"
  sensitive   = true
}

output "cluster_token" {
  value       = data.aws_eks_cluster_auth.main.token
  description = "The token for your EKS Kubernetes API server"
  sensitive   = true
}
