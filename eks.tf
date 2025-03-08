# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "${var.resource_prefix}-eks"
  cluster_version = "1.21"
  subnets         = [aws_subnet.private.id]
  vpc_id          = aws_vpc.main.id

  # Enable control plane logging for audit and troubleshooting.
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    eks_nodes = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1

      instance_type = "t3.medium"
      key_name      = "your-key-pair"  # Replace with your key
    }
  }
}

# Data sources needed to configure the Kubernetes provider.
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}
