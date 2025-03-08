# k8s.tf
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

# Create a service account for the application; we will bind this account to the cluster-admin role.
resource "kubernetes_service_account" "tasky_sa" {
  metadata {
    name      = "${var.resource_prefix}-tasky-sa"
    namespace = "default"
  }
}

# Bind the service account to the cluster-admin role.
resource "kubernetes_cluster_role_binding" "tasky_crb" {
  metadata {
    name = "${var.resource_prefix}-tasky-crb"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tasky_sa.metadata[0].name
    namespace = kubernetes_service_account.tasky_sa.metadata[0].namespace
  }
}

# Create a ConfigMap to hold the "wizexercise.txt" file.
resource "kubernetes_config_map" "wizexercise" {
  metadata {
    name      = "wizexercise-config"
    namespace = "default"
  }
  data = {
    "wizexercise.txt" = "Steve Brewer’s Wiz Technical Interview"
  }
}

# Deploy the containerized web application.
resource "kubernetes_deployment" "tasky" {
  metadata {
    name = "${var.resource_prefix}-tasky-deployment"
    labels = {
      app = "tasky"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "tasky"
      }
    }
    template {
      metadata {
        labels = {
          app = "tasky"
        }
      }
      spec {
        service_account_name = kubernetes_service_account.tasky_sa.metadata[0].name
        container {
          name  = "tasky"
          image = var.container_image
          port {
            container_port = 8080
          }
          # Pass the MongoDB connection string as an environment variable.
          env {
            name  = "MONGO_URI"
            value = "mongodb://${var.mongo_admin_username}:${var.mongo_admin_password}@${aws_instance.db.public_ip}:27017/admin"
          }
          # Mount the ConfigMap so the container gets the wizexercise.txt file.
          volume_mount {
            name       = "wizexercise-volume"
            mount_path = "/app/wizexercise.txt"
            sub_path   = "wizexercise.txt"
          }
        }
        volume {
          name = "wizexercise-volume"
          config_map {
            name = kubernetes_config_map.wizexercise.metadata[0].name
          }
        }
      }
    }
  }
}

# Expose the application to the public internet using a LoadBalancer on port 8080.
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
}
