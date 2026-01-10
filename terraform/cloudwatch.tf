resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}/cluster"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/containerinsights/${var.project_name}/application"
  retention_in_days = 7
}