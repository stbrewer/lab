# variables.tf
variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-west-2"
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  default     = "wizlab"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet (for DB VM)"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet (for EKS)"
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the database VM"
  default     = "t2.micro"
}

# Outdated Ubuntu image (e.g. Ubuntu 14.04 Trusty)
variable "ubuntu_version" {
  description = "Ubuntu AMI name filter (an outdated version)"
  default     = "ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"
}

variable "mongo_admin_username" {
  description = "MongoDB admin username"
  default     = "admin"
}

variable "mongo_admin_password" {
  description = "MongoDB admin password"
  default     = "password"
}

variable "container_image" {
  description = "Container image to deploy (built and pushed via CI)"
  default     = "your-container-registry/tasky:latest"
}
