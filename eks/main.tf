provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.main.token
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}


data "aws_availability_zones" "available" {}


locals {
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# EKS
################################################################################


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
  node_group_name = "${aws_eks_cluster.main.name}-node-group"
  node_role_arn   = var.role_arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = try(var.node_group_scaling_config.desired_size, 2)
    max_size     = try(var.node_group_scaling_config.max_size, 3)
    min_size     = try(var.node_group_scaling_config.min_size, 1)
  }

  instance_types = ["t3.medium"]

}

data "aws_eks_cluster_auth" "main" {
  name = aws_eks_cluster.main.name
}

################################################################################
# Cluster Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
################################################################################

locals {
  cluster_sg_name = coalesce(var.cluster_security_group_name, "${var.cluster_name}-cluster")

  cluster_security_group_id = aws_security_group.cluster.id

  # Do not add rules to node security group if the module is not creating it
  cluster_security_group_rules = {
    ingress_nodes_443 = {
      description                = "Node groups to cluster API"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "ingress"
      source_node_security_group = true
    }
  }
}

resource "aws_security_group" "cluster" {
  name        = var.cluster_security_group_use_name_prefix ? null : local.cluster_sg_name
  name_prefix = var.cluster_security_group_use_name_prefix ? "${local.cluster_sg_name}-" : null
  description = var.cluster_security_group_description
  vpc_id      = var.vpc_id


  tags = merge(
    { "Name" = local.cluster_sg_name },
    var.cluster_security_group_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "cluster" {
  for_each = { for k, v in merge(
    local.cluster_security_group_rules,
    var.cluster_security_group_additional_rules
  ) : k => v }

  # Required
  security_group_id = aws_security_group.cluster.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type

  # Optional
  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", null)
  self                     = lookup(each.value, "self", null)
  source_security_group_id = try(each.value.source_node_security_group, false) ? local.node_security_group_id : lookup(each.value, "source_security_group_id", null)
}

################################################################################
# Node Security Group
# Defaults follow https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
# Plus NTP/HTTPS (otherwise nodes fail to launch)
################################################################################

locals {
  node_sg_name = coalesce(var.node_security_group_name, "${var.cluster_name}-node")

  node_security_group_id = aws_security_group.node.id

  node_security_group_rules = {
    ingress_cluster_443 = {
      description                   = "Cluster API to node groups"
      protocol                      = "tcp"
      from_port                     = 443
      to_port                       = 443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_cluster_kubelet = {
      description                   = "Cluster API to node kubelets"
      protocol                      = "tcp"
      from_port                     = 10250
      to_port                       = 10250
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_self_coredns_tcp = {
      description = "Node to node CoreDNS"
      protocol    = "tcp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
    ingress_self_coredns_udp = {
      description = "Node to node CoreDNS UDP"
      protocol    = "udp"
      from_port   = 53
      to_port     = 53
      type        = "ingress"
      self        = true
    }
  }

  node_security_group_recommended_rules = { for k, v in {
    ingress_nodes_ephemeral = {
      description = "Node to node ingress on ephemeral ports"
      protocol    = "tcp"
      from_port   = 1025
      to_port     = 65535
      type        = "ingress"
      self        = true
    }
    # metrics-server
    ingress_cluster_4443_webhook = {
      description                   = "Cluster API to node 4443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # prometheus-adapter
    ingress_cluster_6443_webhook = {
      description                   = "Cluster API to node 6443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 6443
      to_port                       = 6443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # Karpenter
    ingress_cluster_8443_webhook = {
      description                   = "Cluster API to node 8443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    # ALB controller, NGINX
    ingress_cluster_9443_webhook = {
      description                   = "Cluster API to node 9443/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Allow all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = var.cluster_ip_family == "ipv6" ? ["::/0"] : null
    }
  } : k => v if var.node_security_group_enable_recommended_rules }

  efa_security_group_rules = { for k, v in
    {
      ingress_all_self_efa = {
        description = "Node to node EFA"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }
      egress_all_self_efa = {
        description = "Node to node EFA"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "egress"
        self        = true
      }
    } : k => v if var.enable_efa_support
  }
}

resource "aws_security_group" "node" {

  name        = var.node_security_group_use_name_prefix ? null : local.node_sg_name
  name_prefix = var.node_security_group_use_name_prefix ? "${local.node_sg_name}-" : null
  description = var.node_security_group_description

  tags = merge(
    {
      "Name"                                      = local.node_sg_name
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    },
    var.node_security_group_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "node" {
  for_each = { for k, v in merge(
    local.efa_security_group_rules,
    local.node_security_group_rules,
    local.node_security_group_recommended_rules,
    var.node_security_group_additional_rules,
  ) : k => v }

  # Required
  security_group_id = aws_security_group.node.id
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  type              = each.value.type

  # Optional
  description              = lookup(each.value, "description", null)
  cidr_blocks              = lookup(each.value, "cidr_blocks", null)
  ipv6_cidr_blocks         = lookup(each.value, "ipv6_cidr_blocks", null)
  prefix_list_ids          = lookup(each.value, "prefix_list_ids", [])
  self                     = lookup(each.value, "self", null)
  source_security_group_id = try(each.value.source_cluster_security_group, false) ? local.cluster_security_group_id : lookup(each.value, "source_security_group_id", null)
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



################################################################################
# EKS Blueprints Addons (istio)
################################################################################

locals {
  istio_chart_url     = "https://istio-release.storage.googleapis.com/charts"
  istio_chart_version = "1.20.2"
}
resource "null_resource" "cli_connect_cluster" {
  triggers = {
    cluster_id   = aws_eks_cluster.main.id
    cluster_name = aws_eks_cluster.main.name
    region       = var.region
  }

  depends_on = [
    aws_eks_cluster.main
  ]

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
  }
}

resource "null_resource" "label_default_namespace" {
  triggers = {
    cluster_id   = aws_eks_cluster.main.id
    cluster_name = aws_eks_cluster.main.name
    region       = var.region
  }

  depends_on = [
    aws_eks_cluster.main,
    null_resource.cli_connect_cluster
  ]

  provisioner "local-exec" {
    command = "kubectl label namespace default istio-injection=enabled --overwrite"
  }
}


resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }

  depends_on = [aws_eks_cluster.main, aws_eks_node_group.main]
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16"


  cluster_name      = aws_eks_cluster.main.name
  cluster_endpoint  = aws_eks_cluster.main.endpoint
  cluster_version   = aws_eks_cluster.main.version
  oidc_provider_arn = var.role_arn

  # Due to the lack of permissions to create IAM roles
  # it is not possible to use the aws-ia/eks-blueprints-addons/aws to create the aws_load_balancer_controller.

  helm_releases = {
    istio-base = {
      chart         = "base"
      chart_version = local.istio_chart_version
      repository    = local.istio_chart_url
      name          = "istio-base"
      namespace     = kubernetes_namespace.istio_system.metadata[0].name
    }

    istiod = {
      chart         = "istiod"
      chart_version = local.istio_chart_version
      repository    = local.istio_chart_url
      name          = "istiod"
      namespace     = kubernetes_namespace.istio_system.metadata[0].name

      set = [
        {
          name  = "meshConfig.accessLogFile"
          value = "/dev/stdout"
        }
      ]
    }

    istio-ingress = {
      chart            = "gateway"
      chart_version    = local.istio_chart_version
      repository       = local.istio_chart_url
      name             = "istio-ingress"
      namespace        = "istio-ingress" # per https://github.com/istio/istio/blob/master/manifests/charts/gateways/istio-ingress/values.yaml#L2
      create_namespace = true

      values = [
        yamlencode(
          {
            labels = {
              istio = "ingressgateway"
            }
          }
        )
      ]
    }
  }

  depends_on = [kubernetes_namespace.istio_system]
}

resource "null_resource" "restart_istio_ingress" {
  triggers = {
    cluster_id   = aws_eks_cluster.main.id
    cluster_name = aws_eks_cluster.main.name
    region       = var.region
  }

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_addon.main,
    module.eks_blueprints_addons,
    null_resource.cli_connect_cluster
  ]

  provisioner "local-exec" {
    command = "kubectl rollout restart deployment istio-ingress -n istio-ingress"
  }
}

################################################################################
# Istio Observability Add-ons
################################################################################

resource "helm_release" "istio_addons" {
  name         = "istio-addons"
  chart        = "${path.module}/istio_addons"
  force_update = true

  depends_on = [
    kubernetes_namespace.istio_system
  ]
}