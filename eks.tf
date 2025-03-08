# eks.tf
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.8.4"        # Fully compatible with AWS provider 5.x
  cluster_name    = "${var.resource_prefix}-eks"
  cluster_version = "1.25"

  vpc_id          = aws_vpc.main.id
  subnet_ids      = [aws_subnet.private.id, aws_subnet.private2.id]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  eks_managed_node_groups = {       # Ensure this exact naming (no other node groups!)
    eks_nodes = {
      desired_size   = 1
      max_size       = 1
      min_size       = 1

      instance_types = ["t3.medium"]
      key_name       = "your-key-pair"  # Replace this!

      tags = {
        Name = "${var.resource_prefix}-eks-node"
      }
    }
  }
}


data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_token" {
  value = module.eks.cluster_token
}
