variable "postgres_operator_name" {
  description = "The name of the Helm release of the Postgres operator"
  type        = string
  default     = "postgres-operator"
}

variable "postgres_operator_namespace" {
  description = "The namespace to install the Helm release of the Postgres operator"
  type        = string
  default     = "postgres-operator"
}

variable "postgres_name" {
  description = "The name of the Postgres instance"
  type        = string
  default     = "postgres-ha"
}

variable "postgres_namespace" {
  description = "The namespace to deploy the Postgres instance"
  type        = string
  default     = "postgres-operator"
}

variable "postgres_replicas" {
  description = "The number of replicas for the Postgres instance"
  type        = number
  default     = 2
}

variable "postgres_storage_size" {
  description = "The size of the storage for the Postgres instance"
  type        = string
  default     = "1Gi"
}

variable "postgres_storage_class_name" {
  description = "The name of the storage class to use for Postgres"
  type        = string
  default     = "local-path"
}

variable "dbname" {
  description = "The name of the database to create"
  type        = string
  default     = "postgres"
}

variable "username" {
  description = "The name of the user to create"
  type        = string
  default     = "test"
}
