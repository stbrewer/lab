# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.0"  # Using an older version for simplicity
  cluster_name    = "${var.resource_prefix}-eks"
  cluster_version = "1.25"
  subnets      = [aws_subnet.private.id, aws_subnet.private2.id]
  vpc_id          = aws_vpc.main.id

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  managed_node_groups = {
    eks_nodes = {
      desired_capacity = 1
      max_capacity     = 1
      min_capacity     = 1
      instance_type    = "t3.medium"
      key_name         = "your-key-pair"  # Replace with your actual key pair name
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
