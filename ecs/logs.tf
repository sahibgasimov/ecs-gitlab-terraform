# CloudWatch Log Group for dev environment
resource "aws_cloudwatch_log_group" "dev_log_group" {
  name              = "/ecs/web-app-dev"
  retention_in_days = 180 # 6 months retention

  tags = {
    Environment = var.env_name_dev
    Project     = var.app_name
  }
}

# CloudWatch Log Group for prod environment
resource "aws_cloudwatch_log_group" "prod_log_group" {
  name              = "/ecs/web-app-prod"
  retention_in_days = 180 # 6 months retention

  tags = {
    Environment = var.env_name_prod
    Project     = var.app_name
  }
}
