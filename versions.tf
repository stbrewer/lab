terraform {
  required_version = ">= 1.4.0"

  backend "s3" {
    bucket         = "my-terraform-state-894370042961"   # The S3 bucket name you created
    key            = "terraform/state.tfstate"           # The path within the bucket for your state file
    region         = "us-west-2"                         # Your AWS region
    dynamodb_table = "terraform-locks-894370042961"        # The DynamoDB table name for state locking
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "local" {}
