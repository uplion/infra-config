variable "redis_operator_name" {
  description = "The name of the Helm release of the Redis operator"
  type        = string
  default     = "redis-operator"
}

variable "redis_name" {
  description = "The name of the Redis instance"
  type        = string
  default     = "redis-cluster"
}

variable "namespace" {
  description = "The namespace to install the Helm release of the Redis operator"
  type        = string
  default     = "ot-operators"
}

variable "redis_cluster_size" {
  description = "The number of replicas for the Redis instance"
  type        = number
  default     = 3
}

variable "redis_storage_size" {
  description = "The size of the Redis storage"
  type        = string
  default     = "1Gi"
}

variable "redis_storage_class_name" {
  description = "The name of the storage class to use for Redis"
  type        = string
  default     = "local-path"
}
