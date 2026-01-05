resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "eks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
      {
        Action    = ["sts:AssumeRole", "sts:TagSession"]
        Effect    = "Allow"
        Principal = { Service = "pods.eks.amazonaws.com" }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cloudwatch_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role" "backend_pod_role" {
  name = "${var.project_name}-backend-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = ["sts:AssumeRole", "sts:TagSession"]
      Effect    = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backend_s3_attach" {
  policy_arn = aws_iam_policy.node_s3_access.arn
  role       = aws_iam_role.backend_pod_role.name
}

resource "aws_iam_policy" "node_s3_access" {
  name        = "${var.project_name}-node-s3-policy"
  description = "Allow nodes to access only the QR code bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.qr_codes.arn,
          "${aws_s3_bucket.qr_codes.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "backend_s3" {
  cluster_name    = aws_eks_cluster.main.name
  namespace       = "default"
  service_account = "backend-service-account"
  role_arn        = aws_iam_role.backend_pod_role.arn
}