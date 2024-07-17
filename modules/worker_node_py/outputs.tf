variable "name" {
  description = "The name of the deployment"
  type        = string
  default     = "worker-node-py"
}

variable "replicas" {
  description = "The number of worker nodes"
  type        = number
  default     = 1
}

variable "namespace" {
  description = "The namespace to deploy the worker nodes"
  type        = string
  default     = "worker-node-py"
}

variable "image" {
  description = "The image to use for the worker nodes"
  type        = string
  default     = "yiwencai/workernode:latest"
}

variable "resource" {
  description = "The resource limits and requests for the worker nodes"
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "100m"
    memory = "128Mi"
  }
}

variable "pulsar_url" {
  description = "The URL of the Pulsar broker"
  type        = string
  default     = "pulsar://pulsar-local-broker.pulsar.svc.cluster.local:6650"
}
