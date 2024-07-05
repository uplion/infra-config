output "kubectl_config_command" {
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
  description = "Run this command to configure kubectl to connect to the EKS cluster"
}
