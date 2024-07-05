provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}


locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

###### EKS ######


resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.role_arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = module.vpc.private_subnets
  }
}


resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "eks-node-group"
  node_role_arn   = var.role_arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.micro"]
}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

###### VPC ######

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {}
}

##### EKS Addons #####

data "aws_eks_addon_version" "main" {
  for_each = { for k, v in var.cluster_addons : k => v }

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = coalesce(var.cluster_version, aws_eks_cluster.main.version)
  most_recent        = try(each.value.most_recent, null)
}

resource "aws_eks_addon" "main" {
  for_each = { for k, v in var.cluster_addons : k => v if !try(v.before_compute, false) }

  cluster_name = aws_eks_cluster.main.name
  addon_name   = try(each.value.name, each.key)

  addon_version               = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.main[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }


  tags = try(each.value.tags, {})
}

resource "aws_eks_addon" "before_compute" {
  for_each = { for k, v in var.cluster_addons : k => v if try(v.before_compute, false) }

  cluster_name = aws_eks_cluster.main.name
  addon_name   = try(each.value.name, each.key)

  addon_version               = coalesce(try(each.value.addon_version, null), data.aws_eks_addon_version.main[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts_on_update, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.cluster_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.cluster_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.cluster_addons_timeouts.delete, null)
  }

  tags = try(each.value.tags, {})
}
