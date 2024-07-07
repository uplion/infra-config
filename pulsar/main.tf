resource "helm_release" "pulsar" {
  name            = var.name
  repository      = "https://pulsar.apache.org/charts"
  chart           = "pulsar"
  version         = "3.4.1"
  cleanup_on_fail = true

  namespace        = var.namespace
  create_namespace = true

  values = [
    yamlencode(
      {
        volumes = {
          local_storage = true
        }
      }
    )
  ]
}
