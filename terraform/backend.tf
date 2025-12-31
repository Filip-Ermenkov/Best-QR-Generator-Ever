terraform {
  backend "s3" {
    bucket         = "best-qr-ever-terraform-state"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}