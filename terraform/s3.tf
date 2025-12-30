resource "aws_s3_bucket" "qr_codes" {
  bucket        = "${var.project_name}-generated-codes"
  force_destroy = true
}