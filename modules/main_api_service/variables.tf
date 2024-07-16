variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 3
}

variable "pulsar_url" {
  description = "Pulsar URL"
  type        = string
  default     = "pulsar://localhost:6650"
}

variable "storage_class_name" {
  description = "Storage class name"
  type        = string
  default     = "local-path"
}

variable "name" {
  description = "Name of the service"
  type        = string
  default     = "main-api-service"
}

variable "namespace" {
  description = "Namespace of the service"
  type        = string
  default     = "main-api-service"
}
