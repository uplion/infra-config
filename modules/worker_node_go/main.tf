resource "kubernetes_namespace_v1" "workers_go" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_v1" "workers_go" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.workers_go.metadata.0.name
    labels = {
      app     = var.name
      service = var.name
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.workers_go.metadata[0].labels.app
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8081
    }
  }
}

resource "kubernetes_service_account_v1" "workers_go" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.workers_go.metadata[0].name
    labels = {
      account = var.name
    }
  }
}



resource "kubernetes_deployment_v1" "workers_go" {
  metadata {
    name      = var.name
    namespace = kubernetes_namespace_v1.workers_go.metadata[0].name
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
        service_account_name = kubernetes_service_account_v1.workers_go.metadata.0.name
        container {
          name  = var.name
          image = var.image

          resources {
            limits   = var.resource
            requests = var.resource
          }

          env {
            name  = "PULSAR_URL"
            value = var.pulsar_url
          }
        }
      }
    }
  }
}
