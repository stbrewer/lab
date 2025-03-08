# k8s.tf


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
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
    name = "${var.resource_prefix}-tasky-lb"
  }

  spec {
    selector = {
      app = "tasky"
    }
    type = "LoadBalancer"
    port {
      port        = 8080
      target_port = 8080
    }
  }

  depends_on = [
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

