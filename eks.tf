# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"  # Fully compatible with AWS provider 5.x

  cluster_name    = "wizlab-eks"
  cluster_version = "1.25"

  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.private.id, aws_subnet.private2.id]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  iam_role_arn = aws_iam_role.eks_admin_role.arn

  eks_managed_node_groups = var.deploy_node_group ? {
    eks_nodes = {
      desired_size   = 1
      max_size       = 1
      min_size       = 1

      instance_types = ["t3.medium"]
      key_name       = "wizlab-key"  # 🔥 Replace this with an actual valid key pair!

      # 🛡️ IAM Role for Worker Nodes
      iam_role_arn = data.aws_iam_role.eks_node_role.arn

      tags = {
        Name = "wizlab-eks-node"
      }
    }
  } : {} #
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

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = <<YAML
    - rolearn: ${data.aws_iam_role.eks_node_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    YAML

    mapUsers = <<YAML
    - userarn: "arn:aws:iam::894370042961:user/eks-admin"
      username: admin
      groups:
        - system:masters
    YAML
  }
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
data "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = data.aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = data.aws_iam_role.eks_node_role.name
}

# 🛡️ OIDC Provider for EKS
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_iam_openid_connect_provider" "eks" {
  url = "https://oidc.eks.us-west-2.amazonaws.com/id/CA511CF4FBA87A871816F05CD31D528F"
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
