resource "random_password" "redis" {
  length  = 16
  special = true
}

# resource "kubernetes_persistent_volume" "pv" {
#   count = 6

#   metadata {
#     name   = "${var.pv_name_prefix}-pv-${count.index + 1}"
#     labels = var.pv_labels
#   }

#   spec {
#     storage_class_name = var.storage_class

#     capacity = {
#       storage = var.storage_size # 设置 PV 的存储容量
#     }

#     access_modes = ["ReadWriteOnce"] # 设置访问模式
#     persistent_volume_source {}
#     persistent_volume_reclaim_policy = "Retain" # 设置回收策略
#   }
# }

# resource "helm_release" "redis_cluster" {
#   name            = var.name
#   repository      = "oci://registry-1.docker.io/bitnamicharts"
#   chart           = "redis-cluster"
#   version         = "10.2.6"
#   cleanup_on_fail = true

#   namespace        = var.namespace # per
#   create_namespace = true

#   values = [
#     yamlencode(
#       {
#         global = {
#           storageClass = var.storage_class
#           password     = random_password.redis.result
#         }
#         # cluster = {
#         #   nodes    = var.node_count
#         #   replicas = var.replica_count
#         # }
#         # persistence = {
#         #   storageClass = var.storage_class
#         #   accessModes  = ["ReadWriteOnce"]
#         #   size         = var.storage_size
#         #   matchLabels  = var.pv_labels
#         # }
#         # password = random_password.redis.result
#       }
#     )
#   ]
# }
# resource "helm_release" "example" {
#   name       = "my-redis-release"
#   repository = "https://charts.bitnami.com/bitnami"
#   chart      = "redis"
#   version    = "19.6.1"
# }
