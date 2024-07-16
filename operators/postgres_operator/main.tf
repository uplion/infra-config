# Official Document: https://access.crunchydata.com/documentation/postgres-operator/latest/quickstart
# Helm Chart: https://artifacthub.io/packages/olm/community-operators/postgresql

### Helm
resource "helm_release" "postgres_operator" {
  name            = var.postgres_operator_name
  chart           = "${path.root}/charts/postgres-operator"
  cleanup_on_fail = true

  namespace        = var.postgres_operator_namespace
  create_namespace = true
}

resource "helm_release" "postgres_ha" {
  name            = var.postgres_name
  chart           = "${path.root}/charts/postgres"
  cleanup_on_fail = true

  namespace        = var.postgres_namespace
  create_namespace = true

  depends_on = [helm_release.postgres_operator]

  values = [
    yamlencode({
      imagePostgres   = "registry.developers.crunchydata.com/crunchydata/crunchy-postgres:ubi8-16.3-1"
      postgresVersion = 16
      instances = [{
        name     = "postgres-ha"
        replicas = var.postgres_replicas
        dataVolumeClaimSpec = {
          storageClassName = var.postgres_storage_class_name
          accessModes      = ["ReadWriteOnce"]
          resources = {
            requests = {
              storage = var.postgres_storage_size
            }
          }
        }
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 1
              podAffinityTerm = {
                topologyKey = "kubernetes.io/hostname"
                labelSelector = {
                  matchLabels = {
                    "postgres-operator.crunchydata.com/cluster"      = var.postgres_namespace
                    "postgres-operator.crunchydata.com/instance-set" = "postgres-ha"
                  }
                }
              }
            }]
          }
        }
      }]

      imagePgBackRest = "registry.developers.crunchydata.com/crunchydata/crunchy-pgbackrest:ubi8-2.51-1"
      pgBackRestConfig = {
        repos = [{
          name = "repo1"
          volume = {
            volumeClaimSpec = {
              storageClassName = var.postgres_storage_class_name
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = var.postgres_storage_size
                }
              }
            }
          }
        }]
      }
      backupsSize = var.postgres_storage_size

      imagePgBouncer = "registry.developers.crunchydata.com/crunchydata/crunchy-pgbouncer:ubi8-1.22-1"
      pgBouncerConfig = {
        affinity = {
          podAntiAffinity = {
            preferredDuringSchedulingIgnoredDuringExecution = [{
              weight = 1
              podAffinityTerm = {
                topologyKey = "kubernetes.io/hostname"
                labelSelector = {
                  matchLabels = {
                    "postgres-operator.crunchydata.com/cluster" = var.postgres_name
                    "postgres-operator.crunchydata.com/role"    = "pgbouncer"
                  }
                }
              }
            }]
          }
        }
      }
      users = [{
        databases = [var.dbname]
        name      = var.username
        password = {
          type = "AlphaNumeric"
        }
      }]
    })
  ]
}

data "kubernetes_secret_v1" "postgres_ha" {
  metadata {
    name      = "${var.postgres_name}-pguser-${var.username}"
    namespace = var.postgres_namespace
  }

  depends_on = [helm_release.postgres_ha]
}

# data "kubernetes_secret_v1" "postgres_ha" {
#   metadata {
#     name      = "postgres-ha"
#     namespace = var.postgres_namespace
#   }
# }

### Kustomize # change storage class if use
# ####### Postgres Operator
# resource "kubernetes_namespace_v1" "postgres_operator" {
#     metadata {
#         name = "postgres-operator"
#     }
# }

# module "postgres_operator_kustomization" {
#     source = "${path.root}/modules/kustomization"
#     path = "${path.root}/kustomize/postgres-operator"
# }

# ####### PostgreSQL Cluster
# module "postgres_cluster_kustomization" {
#     source = "${path.root}/modules/kustomization"
#     path = "${path.root}/kustomize/postgres-operator/postgres"
# }
