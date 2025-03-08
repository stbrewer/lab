# ec2.tf
# Lookup an outdated Ubuntu AMI (using filter on the image name)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = [var.ubuntu_version]
  }
}

# Security group for the DB VM
resource "aws_security_group" "db_sg" {
  name        = "${var.resource_prefix}-db-sg"
  description = "Allow SSH from anywhere and MongoDB access from the private subnet"
  vpc_id      = aws_vpc.main.id

  # Allow SSH from anywhere
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow MongoDB (port 27017) only from the Kubernetes (private subnet) CIDR
  ingress {
    description = "MongoDB access from EKS"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource_prefix}-db-sg"
  }
}

# Create the EC2 instance for the database.
resource "aws_instance" "db" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  security_groups             = [aws_security_group.db_sg.name]
  key_name                    = aws_key_pair.lab_key.key_name  # Reference to the Terraform-created key pair

  # Attach the IAM instance profile that grants full admin permissions
  iam_instance_profile = aws_iam_instance_profile.db_instance_profile.name

  # User-data script installs an outdated MongoDB version and sets up a backup cron job.
  user_data = <<-EOF
    #!/bin/bash
    # Update package list and install outdated MongoDB version (example version: 3.2.22)
    apt-get update
    apt-get install -y mongodb-org=3.2.22 mongodb-org-server=3.2.22 mongodb-org-shell=3.2.22 mongodb-org-mongos=3.2.22 mongodb-org-tools=3.2.22

    # Start MongoDB service
    systemctl start mongod
    systemctl enable mongod

    # Create MongoDB admin user for local authentication
    mongo --eval "db.getSiblingDB('admin').createUser({user: '${var.mongo_admin_username}', pwd: '${var.mongo_admin_password}', roles:[{role:'root',db:'admin'}]});"

    # Write a backup script that dumps MongoDB and uploads it to the S3 bucket
    cat << 'EOS' > /usr/local/bin/mongo_backup.sh
    #!/bin/bash
    TIMESTAMP=$(date +%F-%H-%M-%S)
    mongodump --authenticationDatabase admin -u ${var.mongo_admin_username} -p ${var.mongo_admin_password} --out /tmp/backup-$TIMESTAMP
    aws s3 cp /tmp/backup-$TIMESTAMP s3://${aws_s3_bucket.backups.bucket}/backup-$TIMESTAMP --recursive
    EOS
    chmod +x /usr/local/bin/mongo_backup.sh

    # Schedule the backup script to run every hour via cron
    (crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/mongo_backup.sh") | crontab -
  EOF

  tags = {
    Name = "${var.resource_prefix}-db-vm"
  }
}
