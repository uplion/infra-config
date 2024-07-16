terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
    }
  }
}

# provider "kustomization" {
#   kubeconfig_path = module.eks.kubeconfig_path
# }

# data "kustomization_build" "test" {
#   path = var.path
# }

# first loop through resources in ids_prio[0]
resource "kustomization_resource" "p0" {
  for_each = var.ids_prio[0]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.manifests[each.value])
    : var.manifests[each.value]
  )
}

# then loop through resources in ids_prio[1]
# and set an explicit depends_on on kustomization_resource.p0
# wait 2 minutes for any deployment or daemonset to become ready
resource "kustomization_resource" "p1" {
  for_each = var.ids_prio[1]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.manifests[each.value])
    : var.manifests[each.value]
  )
  wait = true
  timeouts {
    create = "2m"
    update = "2m"
  }

  depends_on = [kustomization_resource.p0]
}

# finally, loop through resources in ids_prio[2]
# and set an explicit depends_on on kustomization_resource.p1
resource "kustomization_resource" "p2" {
  for_each = var.ids_prio[2]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(var.manifests[each.value])
    : var.manifests[each.value]
  )

  depends_on = [kustomization_resource.p1]
}
