# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"  # Fully compatible with AWS provider 5.x

  cluster_name    = "wizlab-eks"
  cluster_version = "1.25"

  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.private.id, aws_subnet.private2.id]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # 🛡️ IAM Role for EKS Cluster
  iam_role_arn = aws_iam_role.eks_cluster_role.arn

  eks_managed_node_groups = {
    eks_nodes = {
      desired_size   = 1
      max_size       = 1
      min_size       = 1

      instance_types = ["t3.medium"]
      key_name       = "wizlab-key"  # 🔥 Replace this with an actual valid key pair!

      # 🛡️ IAM Role for Worker Nodes
      iam_role_arn = aws_iam_role.eks_node_role.arn

      tags = {
        Name = "wizlab-eks-node"
      }
    }
  }
}

# 🛡️ IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "wizlab-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 🛡️ IAM Role for Worker Nodes
resource "aws_iam_role" "eks_node_role" {
  name = "wizlab-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# 🛡️ OIDC Provider for EKS
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

resource "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["567DC0929BEF44B0CD9D0D9ABADFB33EA85A536C"]
}


data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  value = data.aws_eks_cluster.eks.certificate_authority[0].data
}

output "cluster_token" {
  value = data.aws_eks_cluster_auth.eks.token
  sensitive = true
}
