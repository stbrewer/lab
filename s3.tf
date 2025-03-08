resource "aws_s3_bucket" "backups" {
  bucket        = "${var.resource_prefix}-backups"
  #acl           = "public-read"  # (if you need public-read; otherwise consider using a more restrictive ACL)
  force_destroy = true           # Allows the bucket to be deleted even if it has objects

  website {
    index_document = "index.html"
  }

  tags = {
    Name = "${var.resource_prefix}-backups"
  }
}

# Disable block public access for this bucket so that our policy can be applied
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "backups_policy" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject", "s3:ListBucket"],
        Resource  = [
          aws_s3_bucket.backups.arn,
          "${aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
}

