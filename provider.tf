provider "aws" {
  region = "us-west-2"

  assume_role {
    role_arn = aws_iam_role.eks_admin_role.arn
  }
}
