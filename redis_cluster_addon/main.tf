resource "random_password" "redis" {
  length  = 16
  special = true
}

resource "helm_release" "redis_cluster" {
  name            = var.name
  repository      = "oci://registry-1.docker.io/bitnamicharts"
  chart           = "redis-cluster"
  version         = "10.2.6"
  cleanup_on_fail = true

  namespace        = var.namespace # per
  create_namespace = true

  values = [
    yamlencode(
      {
        global = {
          storageClass = var.storage_class
          password     = random_password.redis.result
        }
        # cluster = {
        #   nodes    = var.node_count
        #   replicas = var.replica_count
        # }
        persistence = {
          storageClass = var.storage_class
          accessModes  = ["ReadWriteOnce"] # ReadWriteOnce & ReadWriteOncePod supported for local-path provisioner only
          size         = var.storage_size
        }
        # password = random_password.redis.result
      }
    )
  ]
}
