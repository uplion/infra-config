resource "random_password" "postgresql" {
  length  = 16
  special = true
}

resource "random_password" "postgresql_replication_manager" {
  length  = 16
  special = true
}

resource "random_password" "pgpool" {
  length  = 16
  special = true
}

resource "helm_release" "postgresql_ha" {
  name       = var.name
  repository = "oci://registry-1.docker.io/bitnamicharts"
  chart      = "postgresql-ha"
  namespace  = var.namespace
  version    = "14.2.11"
  values = [
    yamlencode(
      {
        global = {
          storageClass = var.storage_class_name
          # TODO to be configured, username using default now
          postgresql = {
            username       = "postgres"
            password       = random_password.postgresql.result
            database       = "api_server"
            repmgrUsername = "repmgr"
            repmgrPassword = random_password.postgresql_replication_manager.result
          }
          pgpool = {
            adminUsername = "admin"
            adminPassword = random_password.pgpool.result
          }
        }
        postgresql = {
          replicaCount = 3 # using default value
        }
        volumePermissions = {
          enabled = false # if use initContainer to adjust permission to write to PV, false = non-root
        }
      }
    )
  ]
}
