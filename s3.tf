data "aws_s3_bucket" "backups" {
  bucket = "wizlab-backups"
}
/*
resource "aws_s3_bucket" "backups" {
  bucket = data.data.aws_s3_bucket.backups.bucket
  #acl           = "public-read"  # (if you need public-read; otherwise consider using a more restrictive ACL)
  force_destroy = true           # Allows the bucket to be deleted even if it has objects

  lifecycle {
    prevent_destroy = true
  }

  website {
    index_document = "index.html"
  }

  tags = {
    Name = "${var.resource_prefix}-backups"
  }
}
*/
resource "aws_s3_bucket_ownership_controls" "backups_ownership" {
  bucket = data.aws_s3_bucket.backups.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = data.aws_s3_bucket.backups.id
  rule {
    id     = "delete-old-backups"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

# Disable block public access for this bucket so that our policy can be applied
resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = data.aws_s3_bucket.backups.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "backups_policy" {
  bucket = data.aws_s3_bucket.backups.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject", "s3:ListBucket"],
        Resource  = [
          data.aws_s3_bucket.backups.arn,
          "${data.aws_s3_bucket.backups.arn}/*"
        ]
      }
    ]
  })
}

