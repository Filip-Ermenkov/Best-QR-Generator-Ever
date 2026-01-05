variable "aws_region" {
  type        = string
  description = "The AWS region where resources will be deployed"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "The name of the project, used as a prefix for resource naming"
  default     = "best-qr-ever"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "The project_name must be lowercase, numbers, and hyphens only."
  }
}

variable "sso_admin_role_arn" {
  type        = string
  description = "The full ARN of the SSO Admin role for cluster console access"
  default     = "arn:aws:iam::176971015975:role/aws-reserved/sso.amazonaws.com/eu-north-1/AWSReservedSSO_AdministratorAccess_ae3a1a8d92448e2b"
}