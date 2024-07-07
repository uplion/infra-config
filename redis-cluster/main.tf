resource "random_password" "redis" {
  length  = 16
  special = true
}

module "pv" {
    source = "./pv"

    pv_count = 6
    storage_class = var.storage_class
    storage = var.storage_size

    pv_name_prefix = "redis-cluster"
    pv_labels = var.pv_labels
}

resource "helm_release" "redis-cluster" {
    name                = var.name
    repository          = "https://charts.bitnami.com/bitnami"
    chart               = "redis-cluster"
    version             = "10.2.6"

    namespace           = var.namespace # per
    create_namespace    = true

    values = [
        yamlencode(
            {
                cluster = {
                    nodes       = var.node_count
                    replicas    = var.replica_count
                }
                persistence = {
                    storageClass = var.storage_class
                    accessModes = ["ReadWriteOnce"]
                    size = var.storage_size
                    matchLabels = local.pv_labels
                }
                password = random_password.redis.result
            }
        )
    ]
}
