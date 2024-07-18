locals {
  service_account_name = "main-api-services-account"
}

resource "kubernetes_namespace_v1" "main_api_service" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_stateful_set_v1" "main_api_services" {
  metadata {
    labels = {
      app = var.name
    }
    name      = "main-api-services"
    namespace = var.namespace
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5

    selector {
      match_labels = {
        app = var.name
      }
    }

    service_name = var.name

    template {
      metadata {
        labels = {
          app = var.name
        }

        annotations = {}
      }

      spec {
        service_account_name = local.service_account_name

        container {
          name              = var.name
          image             = "youxam/uplion-main:latest"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "PULSAR_URL"
            value = var.pulsar_url
          }

          port {
            container_port = 8080
            host_port      = 8081
          }

          resources { # TODO to be configured
            limits = {
              cpu    = "200m"
              memory = "1000Mi"
            }

            requests = {
              cpu    = "200m"
              memory = "1000Mi"
            }
          }

          #   volume_mount {
          #     name       = "config-volume"
          #     mount_path = "/etc/config"
          #   }

          volume_mount {
            name       = "main-api-services-data"
            mount_path = "/etc/main-api-services/data"
            sub_path   = ""
          }

          #   readiness_probe {
          #     http_get {
          #       path = "/-/ready"
          #       port = 8080
          #     }

          #     initial_delay_seconds = 30
          #     timeout_seconds       = 30
          #   }

          #   liveness_probe {
          #     http_get {
          #       path   = "/-/healthy"
          #       port   = 8080
          #       scheme = "HTTPS"
          #     }

          #     initial_delay_seconds = 30
          #     timeout_seconds       = 30
          #   }
        }

        termination_grace_period_seconds = 300

        # volume {
        #   name = "config-volume"

        #   config_map {
        #     name = "prometheus-config"
        #   }
        # }
      }
    }

    update_strategy {
      type = "RollingUpdate"

      rolling_update {
        partition = 1
      }
    }

    volume_claim_template {
      metadata {
        name = "main-api-services-data"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class_name

        resources {
          requests = {
            storage = "1000Mi"
          }
        }
      }
    }

    persistent_volume_claim_retention_policy {
      when_deleted = "Delete"
      when_scaled  = "Delete"
    }
  }
}

resource "kubernetes_service_v1" "main_api_service" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      port        = 8081
      target_port = 8081
    }
  }
}

resource "kubernetes_service_v1" "main_api_service_headless" {
  metadata {
    name      = "main-api-service-headless"
    namespace = var.namespace
  }
  spec {
    selector = {
      app = var.name
    }
    cluster_ip = "None"
    port {
      port        = 8081
      target_port = 8081
    }
  }
}

resource "kubernetes_service_account_v1" "main_api_service_account" {
  metadata {
    name      = local.service_account_name
    namespace = var.namespace
  }
}

resource "kubernetes_secret_v1" "main_api_service_account_secret" {
  metadata {
    name      = "${kubernetes_service_account_v1.main_api_service_account.metadata[0].name}-secret"
    namespace = kubernetes_service_account_v1.main_api_service_account.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account_v1.main_api_service_account.metadata[0].name
    }
  }

  type       = "kubernetes.io/service-account-token"
  depends_on = [kubernetes_service_account_v1.main_api_service_account]
}

resource "kubernetes_role_v1" "main_api_service_role" {
  metadata {
    name      = "main-api-service-role"
    namespace = var.namespace
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "main_api_service_role_binding" {
  metadata {
    name = "main-api-service-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.main_api_service_role.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.main_api_service_account.metadata.0.name
    namespace = var.namespace
  }
}
