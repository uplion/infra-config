terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
    }
    k8s = {
      source  = "metio/k8s"
      version = "2024.7.15"
    }
  }
}

provider "aws" {
  region = var.region
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  token                  = module.eks.cluster_token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = module.eks.cluster_ca_certificate
    token                  = module.eks.cluster_token
  }
}

provider "random" {}

provider "kustomization" {
  kubeconfig_path = "~/.kube/config"
}

provider "k8s" {
  # Configuration options
}

locals {
  tags = {
    GithubRepo = "github.com/uplion/infra-config"
  }
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source = "./eks"

  role_arn = var.role_arn

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
    # aws-ebs-csi-driver     = {}
  }

  node_instance_types = ["c5a.xlarge"]
  node_group_scaling_config = {
    desired_size = 15
    max_size     = 15
    min_size     = 5
  }

  #  EKS K8s API cluster needs to be able to talk with the EKS worker nodes with port 15017/TCP and 15012/TCP which is used by Istio
  #  Istio in order to create sidecar needs to be able to communicate with webhook and for that network passage to EKS is needed.
  node_security_group_additional_rules = {
    ingress_15017 = {
      description                   = "Cluster API - Istio Webhook namespace.sidecar-injector.istio.io"
      protocol                      = "TCP"
      from_port                     = 15017
      to_port                       = 15017
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_15012 = {
      description                   = "Cluster API to nodes ports/protocols"
      protocol                      = "TCP"
      from_port                     = 15012
      to_port                       = 15012
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

}

################################################################################
# Local Path Provisioner
################################################################################

module "local_path_provisioner" {
  source     = "./modules/local_path_provisioner"
  depends_on = [module.eks]
}

################################################################################
# Cert Manager
################################################################################

# resource "helm_release" "cert_manager" {
#   name       = "cert-manager"
#   repository = "https://charts.jetstack.io"
#   chart      = "cert-manager"
#   version    = "v1.15.1"

#   namespace        = "cert-manager"
#   create_namespace = true

#   depends_on = [module.eks]

#   values = [yamlencode({
#     webhook = {
#       securePort = 8090
#     }
#   })]
# }

################################################################################
# Redis
################################################################################

# module "redis_cluster" {
#   source = "./redis_cluster_addon"
#   depends_on = [
#     module.pulsar,
#     module.local_path_provisioner,
#     module.eks
#   ]

#   node_count         = 6
#   replica_count      = 1
#   storage_class_name = "local-path"
#   storage_size       = "1Gi"

#   pv_labels = {
#     app = "redis-cluster"
#   }

#   name      = "redis-cluster"
#   namespace = "redis-cluster"
# }

# module "redis_operator" {
#   source = "./operators/redis_operator"
#   #   depends_on = [module.pulsar]

#   redis_operator_name      = "redis-operator"
#   redis_name               = "redis-cluster"
#   namespace                = "ot-operators"
#   redis_cluster_size       = 3
#   redis_storage_class_name = "local-path"
#   redis_storage_size       = "1Gi"
# }

################################################################################
# PostgreSQL
################################################################################
module "postgresql_ha" {
  source = "./modules/postgresql_ha"
  depends_on = [
    module.eks,
    module.local_path_provisioner,
    # module.pulsar
  ]
  name               = "postgresql-ha"
  namespace          = "postgresql-ha"
  storage_class_name = "local-path"
}
# module "postgres_operator" {
#   source = "./operators/postgres_operator"
#   #   depends_on = [module.pulsar]

#   postgres_operator_name      = "postgres-operator"
#   postgres_operator_namespace = "postgres-operator"
#   postgres_name               = "postgres-ha"
#   postgres_namespace          = "postgres-operator"
#   postgres_replicas           = 2
#   postgres_storage_size       = "1Gi"
#   postgres_storage_class_name = "local-path"
#   username                    = "postgres"
#   dbname                      = "uplion"
# }

################################################################################
# Pulsar
################################################################################
module "pulsar" {
  source     = "./modules/pulsar"
  depends_on = [module.local_path_provisioner]

  cluster_id     = module.eks.cluster_id
  cluster_name   = module.eks.cluster_name
  cluster_region = var.region

  # using default values
  name               = "pulsar-local"
  namespace          = "pulsar"
  storage_class_name = "local-path"
}

# module "pulsar_operator" {
#   source = "./operators/pulsar_operator"
#   depends_on = [
#     module.eks,
#     module.local_path_provisioner,
#     helm_release.cert_manager,
#     module.pulsar
#   ]

#   # using default values
#   name      = "pulsar-operator"
#   namespace = "pulsar-operator"
# }

################################################################################
# KEDA
################################################################################
resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = "2.14.2"

  depends_on = [module.eks]

  namespace        = "keda"
  create_namespace = true

  values = [yamlencode({
    podNamespace = "keda"
  })]
}

################################################################################
# Ingress Gateway
################################################################################

data "kustomization_build" "ingress_gateway_data" {
  path = "${path.root}/kustomize/ingress-gateway"
}

module "ingress_gateway" {
  source     = "./modules/kustomization_apply"
  depends_on = [data.kustomization_build.ingress_gateway_data]
  providers  = { kustomization = kustomization }

  ids_prio  = data.kustomization_build.ingress_gateway_data.ids_prio
  manifests = data.kustomization_build.ingress_gateway_data.manifests
}

data "kubernetes_service_v1" "ingress_gateway" {
  metadata {
    name      = "istio-ingress"
    namespace = "istio-ingress"
  }
  depends_on = [module.ingress_gateway]
}


locals {
  root_url = "http://istio-ingressgateway.istio-system.svc.cluster.local"
}

################################################################################
# AI Model Operator
################################################################################

data "kustomization_build" "ai_model_operator_data" {
  path = "${path.root}/kustomize/ai-model-operator/default"
}

module "ai_model_operator" {
  source = "./modules/kustomization_apply"
  providers = {
    kustomization = kustomization
  }

  depends_on = [data.kustomization_build.ai_model_operator_data]

  ids_prio  = data.kustomization_build.ai_model_operator_data.ids_prio
  manifests = data.kustomization_build.ai_model_operator_data.manifests
}

# TODO add aimodels

################################################################################
# Main API Service
################################################################################

locals {
  pulsar_url = "pulsar://pulsar-local-broker.pulsar.svc.cluster.local:6650"
}

module "main_api_service" {
  source = "./modules/main_api_service"
  #   depends_on = [module.pulsar]

  replicas           = 3
  pulsar_url         = local.pulsar_url
  storage_class_name = "local-path"

  name      = "main-api-service"
  namespace = "main-api-service"
}

################################################################################
# Admin Panel
################################################################################

module "admin_panel" {
  source     = "./modules/admin_panel"
  depends_on = [module.postgresql_ha]

  name      = "admin-panel"
  namespace = "admin-panel"
  replicas  = 1
  resource = {
    cpu    = "100m"
    memory = "256Mi"
  }
  postgres_config = {
    username = "postgres"
    password = "GO)Ns6]Tp3Z$TbW1"
    host     = "postgresql-ha-pgpool.postgresql-ha.svc.cluster.local"
    port     = 5432
    dbname   = "uplion"
  }

  # postgres_config = {
  #   username = module.postgres_operator.postgres_username
  #   password = module.postgres_operator.postgres_password
  #   host     = module.postgres_operator.postgres_host
  #   port     = module.postgres_operator.postgres_port
  #   dbname   = module.postgres_operator.postgres_dbname
  # }
}

# ################################################################################
# # Frontend
# ################################################################################

module "frontend" {
  source     = "./modules/frontend"
  depends_on = [module.eks]

  name      = "frontend"
  namespace = "frontend"
  replicas  = 30
  resource = {
    cpu    = "100m"
    memory = "256Mi"
  }

  openai_host = "main-api-service.main-api-service.svc.cluster.local"
  openai_port = 8080
}

# ################################################################################
# # AI Models
# ################################################################################
# data "kustomization_build" "aimodel_go_data" {
#   path = "${path.root}/kustomize/aimodel-go"
# }

# module "aimodel_go" {
#   source = "./modules/kustomization_apply"
#   providers = {
#     kustomization = kustomization
#   }
#   depends_on = [module.ai_model_operator]

#   ids_prio  = data.kustomization_build.aimodel_go_data.ids_prio
#   manifests = data.kustomization_build.aimodel_go_data.manifests
# }

# data "kustomization_build" "aimodel_py_data" {
#   path = "${path.root}/kustomize/aimodel-py"
# }

# module "aimodel_py" {
#   source = "./modules/kustomization_apply"
#   providers = {
#     kustomization = kustomization
#   }
#   depends_on = [module.ai_model_operator]

#   ids_prio  = data.kustomization_build.aimodel_py_data.ids_prio
#   manifests = data.kustomization_build.aimodel_py_data.manifests
# }

# ################################################################################
# # Test
# ################################################################################
# # TODO change to bigger node
# # resource "kubernetes_deployment_v1" "pressure_test" {
# #   metadata {
# #     name = "pressure-test"
# #     labels = {
# #       app = "pressure-test"
# #     }
# #   }

# #   depends_on = [data.kubernetes_service_v1.ingress_gateway]
# #   spec {
# #     replicas = 1

# #     selector {
# #       match_labels = {
# #         app = "pressure-test"
# #       }
# #     }

# #     template {
# #       metadata {
# #         labels = {
# #           app = "pressure-test"
# #         }
# #       }

# #       spec {
# #         container {
# #           name  = "pressure-test"
# #           image = "sherlockedhzoi/pressure-test:lastest"

# #           resources {
# #             limits = {
# #               cpu    = "100m"
# #               memory = "256Mi"
# #             }
# #             requests = {
# #               cpu    = "100m"
# #               memory = "256Mi"
# #             }
# #           }

# #           env {
# #             name  = "TEST_URL"
# #             value = local.root_url
# #           }
# #         }
# #       }
# #     }
# #   }
# # }
