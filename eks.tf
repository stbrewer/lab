# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "18.0.0"  # Using an older version for simplicity
  cluster_name    = "${var.resource_prefix}-eks"
  cluster_version = "1.22"
  subnets         = [aws_subnet.private.id, aws_subnet.private2.id]
  vpc_id          = aws_vpc.main.id

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  worker_groups = [
    {
      name                 = "eks_nodes"
      instance_type        = "t3.medium"
      asg_desired_capacity = 1
      asg_min_size         = 1
      asg_max_size         = 1
      key_name             = "your-key-pair"
    }
  ]
}

# Data sources needed to configure the Kubernetes provider.
data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}
