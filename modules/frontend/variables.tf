variable "name" {
  description = "The name of the application"
  type        = string
  default     = "frontend"
}

variable "namespace" {
  description = "The namespace to deploy the application"
  type        = string
  default     = "frontend"
}

variable "resource" {
  description = "The resource to deploy"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "100m"
    memory = "128Mi"
  }
}

variable "replicas" {
  description = "The number of replicas to deploy"
  type        = number
  default     = 3
}
