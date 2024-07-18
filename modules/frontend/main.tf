resource "kubernetes_namespace_v1" "frontend" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.frontend.metadata.0.name
    labels = {
      app     = var.name
      service = var.name
    }
  }

  spec {
    selector = {
      app = var.name
    }

    port {
      name        = "http"
      port        = 3000
      target_port = 3000
    }
  }
}

resource "kubernetes_service_account_v1" "frontend" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.frontend.metadata.0.name

    labels = {
      account = var.name
    }
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.frontend.metadata.0.name

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
        service_account_name = kubernetes_service_account_v1.frontend.metadata.0.name
        container {
          name  = var.name
          image = "youxam/uplion-frontend:latest"

          port {
            container_port = 3000
            host_port      = 3000
          }

          env {
            name  = "OPENAI_BASE_URL"
            value = "http://${var.openai_host}:${var.openai_port}/api/v1"
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
}
