
locals{
  redis_cluster_chart_url       = "https://charts.bitnami.com/bitnami"
  redis_cluster_chart_version   = "10.2.6"
  
  pv_labels = {
    app = "redis-cluster"
  }
}

module "pv" {
    source = "../pv"

    pv_count = 6
    storage_class = "standard"
    storage = "1Gi"

    pv_name_prefix = "redis-cluster"
    pv_labels = local.pv_labels
}

resource "helm_release" "redis-cluster" {
    name                = "redis-cluster"
    repository          = local.redis_cluster_chart_url
    chart               = "redis-cluster"
    version             = local.redis_cluster_chart_version

    namespace           = "redis-cluster" # per
    create_namespace    = true

    values = [
        yamlencode(
            {
                cluster = {
                    nodes       = 6
                    replicas    = 1
                }
                persistence = {
                    storageClass = "standard"
                    accessModes = ["ReadWriteOnce"]
                    size = "1Gi"
                    matchLabels = local.pv_labels
                }
                password = "123456"
            }
        )
    ]
}
