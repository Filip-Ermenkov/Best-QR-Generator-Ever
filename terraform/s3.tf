resource "aws_s3_bucket" "qr_codes" {
  bucket        = "${var.project_name}-generated-codes"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "qr_codes" {
  bucket = aws_s3_bucket.qr_codes.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "qr_codes" {
  bucket = aws_s3_bucket.qr_codes.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "qr_codes" {
  bucket = aws_s3_bucket.qr_codes.id
  versioning_configuration {
    status = "Enabled"
  }
}