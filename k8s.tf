# k8s.tf

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = module.eks.cluster_token
}

# All Kubernetes resources must explicitly depend on these data sources:

resource "kubernetes_service_account" "tasky_sa" {
  metadata {
    name      = "${var.resource_prefix}-tasky-sa"
    namespace = "default"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "kubernetes_config_map" "wizexercise" {
  metadata {
    name      = "wizexercise-config"
    namespace = "default"
  }

  data = {
    "wizexercise.txt" = "Steve Brewer’s Wiz Technical Interview"
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

resource "kubernetes_service" "tasky_lb" {
  metadata {
    name = "wizlab-tasky-lb"
    namespace = "default"
  }

  spec {
    selector = {
      app = "wizlab-tasky"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}

#  depends_on = [
#    data.aws_eks_cluster.eks,
#    data.aws_eks_cluster_auth.eks
#  ]
#}


