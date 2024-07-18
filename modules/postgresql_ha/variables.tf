variable "name" {
  description = "Name of the Helm release"
  type        = string
  default     = "postgresql-ha"
}

variable "namespace" {
  description = "Namespace of the Helm release"
  type        = string
  default     = "postgresql-ha"
}

variable "storage_class_name" {
  description = "Storage class name for the PostgreSQL HA"
  type        = string
  default     = "local-path"
}
