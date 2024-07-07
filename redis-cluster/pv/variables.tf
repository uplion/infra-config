variable "pv_count" {
  description = "Number of Persistent Volumes to create"
  type        = number
  default     = 3 # 设置你需要的 PV 数量
}

variable "storage_class" {
  description = "Storage class to use for the PV"
  type        = string
  default     = "standard"
}

variable "storage_size" {
  description = "Storage size for the PV"
  type        = string
  default     = "1Gi"
}

# ----------------------------------------

variable "pv_name_prefix" {
  description = "Prefix for the PV name"
  type        = string
  default     = "my-app"
}

variable "pv_labels" {
  description = "Labels to apply to the PV"
  type        = map(string)
  default = {
    app = "my-app"
  }
}