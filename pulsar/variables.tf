variable "name" {
  description = "The name of the Helm release of pulsar"
  type        = string
  default     = "pulsar"
}

variable "namespace" {
  description = "The namespace to install the Helm release of pulsar"
  type        = string
  default     = "pulsar"
}

# ---------------------------------
variable "cluster_id" {
  description = "The ID of the EKS cluster"
  type        = string
}
variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}
variable "cluster_region" {
  description = "The region of the EKS cluster"
  type        = string
  default     = "us-east-1"
}

variable "prerequirities" {
  description = "The prerequisites for the resources"
  type        = list(string)
}
