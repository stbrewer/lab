# s3.tf
resource "aws_s3_bucket" "backups" {
  bucket        = "${var.resource_prefix}-backups"
  acl           = "public-read"  # Publicly readable backups
  force_destroy = true           # Allows bucket to be destroyed with objects inside

  website {
    index_document = "index.html"
  }

  tags = {
    Name = "${var.resource_prefix}-backups"
  }
}

# Bucket policy to allow public listing and read access.
resource "aws_s3_bucket_policy" "backups_policy" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = ["s3:GetObject", "s3:ListBucket"],
      Resource  = [
        aws_s3_bucket.backups.arn,
        "${aws_s3_bucket.backups.arn}/*"
      ]
    }]
  })
}
