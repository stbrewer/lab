# iam.tf
# Create an IAM Role with full administrative privileges (intentionally insecure)
resource "aws_iam_role" "db_instance_role" {
  name = "${var.resource_prefix}-db-instance-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "db_instance_policy" {
  name = "${var.resource_prefix}-db-instance-policy"
  role = aws_iam_role.db_instance_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "*",
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "db_instance_profile" {
  name = "${var.resource_prefix}-db-instance-profile"
  role = aws_iam_role.db_instance_role.name
}
