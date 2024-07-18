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
  version    = "14.2.11"

  namespace        = var.namespace
  create_namespace = true

  set {
    name  = "postgresql.password"
    value = "GO)Ns6]Tp3Z$TbW1"
  }

  set {
    name  = "postgresql.repmgrPassword"
    value = "uae->A_{I-oygQKG"
  }

  set {
    name  = "pgpool.adminPassword"
    value = "8DrYX7EB4*fU[Sjc"
  }

  values = [
    yamlencode(
      {
        global = {
          storageClass = var.storage_class_name
          # TODO to be configured, username using default now
          postgresql = {
            username       = "postgres"
            password       = "GO)Ns6]Tp3Z$TbW1"
            database       = "api_server"
            repmgrUsername = "repmgr"
            repmgrPassword = "uae->A_{I-oygQKG"
          }
          pgpool = {
            adminUsername = "admin"
            adminPassword = "8DrYX7EB4*fU[Sjc"
          }
        }
        postgresql = {
          replicaCount = 3 # using default value
          resources = {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            password       = "GO)Ns6]Tp3Z$TbW1"
            repmgrPassword = "uae->A_{I-oygQKG"
          }
        }
        pgpool = {
          adminPassword = "8DrYX7EB4*fU[Sjc"
        }
        volumePermissions = {
          enabled = false # if use initContainer to adjust permission to write to PV, false = non-root
        }
      }
    )
  ]
}
