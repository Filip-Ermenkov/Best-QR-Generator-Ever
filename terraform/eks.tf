locals {
  parts = split("/", var.sso_admin_role_arn)
  sso_role_arn_cleaned = "${local.parts[0]}/${element(local.parts, length(local.parts) - 1)}"
}

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "main" {
  name     = var.project_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(module.vpc.public_subnets, module.vpc.private_subnets)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_cloudwatch_log_group.eks
  ]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn

  subnet_ids = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2023_x86_64_STANDARD"

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy,
  ]
}

resource "aws_eks_addon" "pod_identity" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_access_entry" "sso_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = local.sso_role_arn_cleaned
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "sso_admin_policy" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.sso_role_arn_cleaned

  access_scope {
    type = "cluster"
  }
}