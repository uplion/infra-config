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

variable "openai_host" {
  description = "The host of the OpenAI API"
  type        = string
  default     = "api.openai.com"
}

variable "openai_port" {
  description = "The port of the OpenAI API"
  type        = number
  default     = 443
}
