variable "name" {
  description = "Name of the deployment"
  type        = string
  default     = "admin-panel"
}

variable "namespace" {
  description = "Namespace of the deployment"
  type        = string
  default     = "admin-panel"
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "resource" {
  description = "Resource Requirement (same as limit)"
  type = object({
    cpu    = string
    memory = string
  })

  default = {
    cpu    = "100m"
    memory = "256Mi"
  }
}

variable "postgres_config" {
  description = "Postgres configuration"
  type = object({
    username = string
    password = string
    host     = string
    port     = string
    dbname   = string
  })
}
