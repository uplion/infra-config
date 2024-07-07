variable "role_arn" {
  description = "The ARN of the IAM role that provides permissions for the EKS control plane to make calls to AWS API operations on your behalf."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy the EKS cluster."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the EKS cluster."
  type        = string
  default     = "eks-cluster"
}
