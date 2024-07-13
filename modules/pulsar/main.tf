### Official Helm Chart
resource "null_resource" "prepare_helm_release" {
  triggers = {
    cluster_id   = var.cluster_id
    cluster_name = var.cluster_name
    region       = var.cluster_region
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/pulsar/prepare_helm_release.sh -n ${var.namespace} -k ${var.name} -c"
  }
}

resource "helm_release" "pulsar" {
  name  = var.name
  chart = "${path.root}/charts/pulsar"

  namespace         = var.namespace
  create_namespace  = true
  dependency_update = true

  values = [yamlencode({
    volumes = {
      local_storage = (var.storage_class_name == "local-path")
    }
    components = {
      pulsar_manager = true
    }
  })]
}

### Datastax Helm Chart
# resource "helm_release" "pulsar" {
#   name            = var.name
#   repository      = "http://datastax.github.io/pulsar-helm-chart"
#   chart           = "pulsar"
#   version         = "3.2.3"
#   cleanup_on_fail = true

#   namespace        = var.namespace
#   create_namespace = true

#   values = [
#     yamlencode(
#       {
#         restartOnConfigMapChange = {
#           enabled = true
#         }
#         default_storage = {
#           existingStorageClassName = var.storage_class_name
#         }
#       }
#     )
#   ]
# }
