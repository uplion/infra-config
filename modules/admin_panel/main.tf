resource "kubernetes_namespace_v1" "admin_panel" {
  metadata {
    name = var.namespace
    labels = {
      istio-injection = "enabled"
    }
  }
}

resource "kubernetes_service_v1" "admin_panel" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.admin_panel.metadata.0.name
    labels = {
      app     = var.name
      service = var.name
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.admin_panel.metadata.0.labels.app
    }
    port {
      name        = "http"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_service_account_v1" "admin_panel" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.admin_panel.metadata.0.name
    labels = {
      account = var.name
    }
  }
}

resource "kubernetes_cluster_role_v1" "admin_panel" {
  metadata {
    name = var.name
  }

  rule {
    api_groups = ["model.youxam.com"]
    resources  = ["aimodels"]
    verbs      = ["list", "create", "get", "update", "delete", "watch"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "admin_panel" {
  metadata {
    name = var.name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.admin_panel.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.admin_panel.metadata.0.name
    namespace = kubernetes_namespace_v1.admin_panel.metadata.0.name
  }
}

resource "kubernetes_deployment_v1" "admin_panel" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.admin_panel.metadata.0.name
    labels = {
      app = var.name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = var.name
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.admin_panel.metadata.0.name

        container {
          image = "youxam/uplion-admin-panel:latest"
          name  = "admin-panel-app"

          #   resources {
          #     limits   = var.resource
          #     requests = var.resource
          #   }

          port {
            container_port = 3000
          }

          env {
            name  = "DATABASE_URL"
            value = "postgresql://${var.postgres_config.username}:${urlencode(var.postgres_config.password)}@${var.postgres_config.host}:${var.postgres_config.port}/${var.postgres_config.dbname}?schema=public"
          }

          env {
            name  = "IMAGE"
            value = "yiwencai/workernode:latest"
          }

          env {
            name  = "REPLICAS"
            value = 3
          }

          env {
            name  = "MSG_BACKLOG_THRESHOLD"
            value = 2
          }

          #   liveness_probe {
          #     http_get {
          #       path = "/"
          #       port = 80

          #       http_header {
          #         name  = "X-Custom-Header"
          #         value = "Awesome"
          #       }
          #     }

          #     initial_delay_seconds = 3
          #     period_seconds        = 3
          #   }
        }
      }
    }
  }
}
