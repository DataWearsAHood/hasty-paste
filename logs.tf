
## Create log group for our service

resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/${local.app-name}/ecs"
  retention_in_days = 30  # var.retention_in_days
}
