resource "aws_ecr_repository" "ecr" {
  name         = "${local.app-name}-ecr"
  # force_delete = var.ecr_force_delete

  image_scanning_configuration {
    scan_on_push = true
  }
}

## Creates an ECS Cluster
resource "aws_ecs_cluster" "default" {
  name  = "${local.app-name}_ECSCluster"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name     = "${local.app-name}_ECSCluster"
  }
}

## Creates ECS Service

resource "aws_ecs_service" "service" {
  name                               = "${local.app-name}_ECS_Service"
  iam_role                           = aws_iam_role.ecs_service_role.arn
  cluster                            = aws_ecs_cluster.default.id
  task_definition                    = aws_ecs_task_definition.default.arn
  desired_count                      = 1  # var.ecs_task_desired_count
  deployment_minimum_healthy_percent = 0  # var.ecs_task_deployment_minimum_healthy_percent
  deployment_maximum_percent         = 101  # var.ecs_task_deployment_maximum_percent

  load_balancer {
    target_group_arn = aws_alb_target_group.service_target_group.arn
    container_name   = local.app-name
    container_port   = local.app-internal-port
  }

  ## Spread tasks evenly accross all Availability Zones for High Availability
  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }
  
  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  ## Do not update desired count again to avoid a reset to this number on every deployment
  lifecycle {
    ignore_changes = [desired_count]
  }
}