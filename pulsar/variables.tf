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
