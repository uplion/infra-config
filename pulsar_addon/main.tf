resource "null_resource" "install_cert_manager" {
  triggers = {
    cluster_id   = var.cluster_id
    cluster_name = var.cluster_name
    region       = var.cluster_region
  }
  provisioner "local-exec" {
    command = "${path.module}/scripts/cert-manager/install-cert-manager.sh"
  }
}
resource "null_resource" "prepare_helm_release" {
  triggers = {
    cluster_id   = var.cluster_id
    cluster_name = var.cluster_name
    region       = var.cluster_region
  }

  depends_on = [
    null_resource.install_cert_manager
  ]

  provisioner "local-exec" {
    command = "${path.module}/scripts/pulsar/prepare_helm_release.sh -n ${var.namespace} -k ${var.name} -c"
  }
}
resource "helm_release" "pulsar" {
  name            = var.name
  repository      = "http://datastax.github.io/pulsar-helm-chart"
  chart           = "pulsar"
  version         = "3.2.3"
  cleanup_on_fail = true

  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode(
      {
        restartOnConfigMapChange = {
          enabled = true
        }
        default_storage = {
          existingStorageClassName = var.storage_class_name
        }
      }
    )
  ]
}
