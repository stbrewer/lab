# Generate a new RSA private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair using the generated public key
resource "aws_key_pair" "lab_key" {
  key_name   = "${var.resource_prefix}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}
