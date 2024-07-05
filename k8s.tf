provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.main.token
}

output "kubernertes_info" {
  value = {
    host           = aws_eks_cluster.main.endpoint
    token          = data.aws_eks_cluster_auth.main.token
    ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  }
  sensitive = true
}

# resource "kubernetes_manifest" "frontend" {
#   manifest = {
#     apiVersion = "apps/v1"
#     kind       = "Deployment"
#     metadata   = {
#       name = "frontend"
#       namespace = "default"
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "frontend"
#         }
#       }
#       replicas = 2
#       template = {
#         metadata = {
#           labels = {
#             app = "frontend"
#           }
#         }
#         spec = {
#           containers = [{
#             name  = "frontend"
#             image = "nginx"
#           }]
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "backend" {
#   manifest = {
#     apiVersion = "apps/v1"
#     kind       = "Deployment"
#     metadata   = {
#       name = "backend"
#       namespace = "default"
#     }
#     spec = {
#       selector = {
#         matchLabels = {
#           app = "backend"
#         }
#       }
#       replicas = 2
#       template = {
#         metadata = {
#           labels = {
#             app = "backend"
#           }
#         }
#         spec = {
#           containers = [{
#             name  = "backend"
#             image = "my-backend-image"
#           }]
#         }
#       }
#     }
#   }
# }
