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

# provider "kustomization" {
#   kubeconfig_path = module.eks.kubeconfig_path
# }


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

  node_instance_types = ["t3.large"]

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
    module.pulsar
    # helm_release.cert_manager
  ]

  redis_operator_name      = "redis-operator"
  redis_operator_namespace = "redis-operator"
  redis_name               = "redis-cluster"
  redis_namespace          = "redis-operator"
  redis_cluster_size       = 3
  redis_storage_size       = "1Gi"
  redis_storage_class_name = "local-path"
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
    module.pulsar
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
  name               = "pulsar"
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
