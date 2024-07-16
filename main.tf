terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "0.9.6"
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

  node_instance_types = ["t3.medium"]

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

module "redis_operator" {
  source = "./operators/redis_operator"
  depends_on = [
    module.eks,
    module.local_path_provisioner,
    module.pulsar,
    # helm_release.cert_manager
  ]

  redis_operator_name      = "redis-operator"
  redis_name               = "redis-cluster"
  namespace                = "ot-operators"
  redis_cluster_size       = 3
  redis_storage_class_name = "local-path"
  redis_storage_size       = "1Gi"
}

################################################################################
# PostgreSQL
################################################################################
# module "postgresql_ha" {
#   source = "./postgresql_ha_addon"
#   depends_on = [
#     module.eks,
#     module.local_path_provisioner,
#     module.pulsar
#   ]
#   storage_class_name = "local-path"
# }
module "postgres_operator" {
  source = "./operators/postgres_operator"
  depends_on = [
    module.eks,
    module.local_path_provisioner,
    module.pulsar,
  ]

  postgres_operator_name      = "postgres-operator"
  postgres_operator_namespace = "postgres-operator"
  postgres_name               = "postgres-ha"
  postgres_namespace          = "postgres-operator"
  postgres_replicas           = 2
  postgres_storage_size       = "1Gi"
  postgres_storage_class_name = "local-path"
}

################################################################################
# Pulsar
################################################################################
module "pulsar" {
  source = "./modules/pulsar"
  depends_on = [
    module.local_path_provisioner,
    module.eks
    # helm_release.cert_manager
  ]

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

# data "kustomization_build" "ingress_gateway_data" {
#   path = "${path.root}/kustomize/ingress-gateway"
# }

# module "ingress_gateway" {
#   source     = "./modules/kustomization_apply"
#   depends_on = [module.eks, module.main_api_service, module.admin_panel, module.frontend]
#   providers = {
#     kustomization = kustomization
#   }

#   ids_prio  = data.kustomization_build.ingress_gateway_data.ids_prio
#   manifests = data.kustomization_build.ingress_gateway_data.manifests
# }

################################################################################
# AI Model Operator
################################################################################

# data "kustomization_build" "ai_model_operator_data" {
#   path = "${path.root}/kustomize/ai-model-operator/default"
# }

# module "ai_model_operator" {
#   source = "./modules/kustomization_apply"
#   providers = {
#     kustomization = kustomization
#   }

#   depends_on = [
#     module.eks,
#     module.local_path_provisioner,
#     module.pulsar
#   ]

#   ids_prio  = data.kustomization_build.ai_model_operator_data.ids_prio
#   manifests = data.kustomization_build.ai_model_operator_data.manifests
# }

################################################################################
# Main API Service
################################################################################

# locals {
#   pulsar_url = "pulsar://pulsar-local-broker.pulsar.svc.cluster.local:6650"
# }

# module "main_api_service" {
#   source     = "./modules/main_api_service"
#   depends_on = [module.eks, module.local_path_provisioner, module.pulsar]

#   replicas           = 3
#   pulsar_url         = local.pulsar_url
#   storage_class_name = "local-path"

#   name      = "main-api-service"
#   namespace = "main-api-service"
# }

################################################################################
# Admin Panel
################################################################################

# module "admin_panel" {
#   source     = "./modules/admin_panel"
#   depends_on = [module.eks, module.local_path_provisioner, module.postgres_operator]

#   name      = "admin-panel"
#   namespace = "admin-panel"
#   replicas  = 1
#   resource = {
#     cpu    = "100m"
#     memory = "256Mi"
#   }

#   postgres_config = { # TODO to be configured
#     username = module.postgres_operator.postgres_username
#     password = module.postgres_operator.postgres_password
#     host     = module.postgres_operator.postgres_host
#     port     = module.postgres_operator.postgres_port
#     dbname   = module.postgres_operator.postgres_dbname
#   }
# }

################################################################################
# Frontend
################################################################################

# module "frontend" {
#   source     = "./modules/frontend"
#   depends_on = [module.eks, module.local_path_provisioner, module.main_api_service]

#   name      = "frontend"
#   namespace = "frontend"
#   replicas  = 3
#   resource = {
#     cpu    = "100m"
#     memory = "256Mi"
#   }
# }

################################################################################
# Frontend
################################################################################
# locals {
#   pulsar_url = "pulsar://pulsar-local-broker.pulsar.svc.cluster.local:6650"
# }

# module "workers" {
#   source     = "./modules/worker_nodes"
#   depends_on = [module.eks, module.local_path_provisioner, module.pulsar, module.ai_model_operator]

#   name       = "worker-nodes"
#   namespace  = "worker-nodes"
#   replicas   = 1
#   pulsar_url = local.pulsar_url
#   resource = {
#     cpu    = "100m"
#     memory = "256Mi"
#   }
# }
