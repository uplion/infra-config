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
      port        = 80
      target_port = 3000
    }
  }
}

resource "kubernetes_service_account_v1" "frontend" {
  metadata {
    name = var.name

    labels = {
      account = var.name
    }
  }
}

resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = var.name

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
          image = "youxam/uplion-frontend:lastest"

          port {
            container_port = 3000
          }

          env {
            name  = "OPENAI_BASE_URL"
            value = "http://main-api-service.main-api-service.svc.cluster.local/api/v1"
          }

          image_pull_policy = "IfNotPresent"
        }
      }
    }
  }
}
