# outputs.tf
output "db_public_ip" {
  description = "Public IP of the Database VM"
  value       = aws_instance.db.public_ip
}

output "s3_bucket" {
  description = "Name of the S3 bucket for backups"
  value       = aws_s3_bucket.backups.bucket
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_id
}

#output "cluster_endpoint" {
#  value = module.eks.cluster_endpoint
#}

/*
output "load_balancer_url" {
  description = "URL to access the containerized web application"
  value       = kubernetes_service.tasky_lb.status[0].load_balancer[0].ingress[0].hostname
}
*/
