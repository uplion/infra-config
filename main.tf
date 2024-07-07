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
# Redis
################################################################################

# module redis {
#     source = "./redis-cluster"
    
#     node_count     = 6
#     replica_count  = 1
#     storage_class  = "gp2"
#     storage_size   = "1Gi"
    
#     pv_name_prefix = "redis-cluster"
#     pv_labels      = {
#         app = "redis-cluster"
#     }
    
#     name      = "redis-cluster"
#     namespace = "redis-cluster"
# }