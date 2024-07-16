# variable "path" {
#   description = "Path to the kustomization directory"
#   type        = string
# }

variable "ids_prio" {
  description = "List of resource ids sorted by priority"
  type        = list(set(string))
}

variable "manifests" {
  description = "Map of resource ids to manifests"
  type        = map(string)

}
