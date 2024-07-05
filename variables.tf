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

variable "cluster_version" {
  description = "The desired Kubernetes version for creating the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }
}

variable "cluster_addons_timeouts" {
  description = "Create, update, and delete timeout configurations for the cluster addons"
  type        = map(string)
  default     = {}
}
