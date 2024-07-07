variable "node_count" {
  type        = number
  default     = 6
  description = "Number of redis nodes"
}
variable "replica_count" {
  type        = number
  default     = 1
  description = "Number of replicas"
}

variable "storage_class" {
  type        = string
  default     = "standard"
  description = "Storage class to use for PVs"
}
variable "storage_size" {
  type        = string
  default     = "10Gi"
  description = "Storage size for each PV"
}
variable "pv_name_prefix" {
  type        = string
  default     = "redis-cluster"
  description = "Prefix for PV names"
}
variable "pv_labels" {
  type = map(string)
  default = {
    app = "redis-cluster"
  }
  description = "Labels to apply to PVs"
}

variable "name" {
  type        = string
  default     = "redis-cluster"
  description = "Name of the Redis cluster"
}

variable "namespace" {
  type        = string
  default     = "redis-cluster"
  description = "Kubernetes namespace"
}
