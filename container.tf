# resource "aws_ecr_repository" "ecr" {
#   name         = "${local.app-name}-ecr"
#   # force_delete = var.ecr_force_delete

#   image_scanning_configuration {
#     scan_on_push = true
#   }
# }

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
  # deployment_minimum_healthy_percent = 0  # var.ecs_task_deployment_minimum_healthy_percent
  # deployment_maximum_percent         = 101  # var.ecs_task_deployment_maximum_percent

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

  tags = {
    Name     = "${local.app-name}_ECSService"
  }
}

## Creates ECS Task Definition
resource "aws_ecs_task_definition" "default" {
  family             = "${local.app-name}_ECS_TaskDefinition"
  # [?] newtork_mode = "bridge" [?]
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_iam_role.arn

  container_definitions = jsonencode([
    {
      name         = local.app-name
      image        = "${local.manual-ecr-repo-url}:latest"   # :${var.hash}"
      cpu          = 256  # var.cpu_units
      memory       = 512  # var.memory
      essential    = true
      portMappings = [
        {
          containerPort = local.app-internal-port
          hostPort      = 0
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.log_group.name,
          "awslogs-region"        = local.region,
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name     = "${local.app-name}_ECSTask"
  }
}

# https://stackoverflow.com/questions/59591109/terraform-no-container-instances-were-found-in-your-cluster
# resource "aws_launch_configuration" "ecs-launch-configuration" {
#   name                 = "ecs-launch-configuration"
#   image_id             = "ami-0d5d9d301c853a04a"
#   instance_type        = "t2.micro"
#   iam_instance_profile = "ecsInstanceRole"

#   root_block_device {
#     volume_type           = "standard"
#     volume_size           = 35
#     delete_on_termination = true
#   }

#   security_groups = ["${aws_security_group.ecs-vpc-secgroup.id}"]
#   associate_public_ip_address = "true"
#   key_name                    = "myapp"
#   user_data                   = <<-EOF
#                                       #!/bin/bash
#                                       echo ECS_CLUSTER=${aws_ecs_cluster.public-ecs-cluster.name} >> /etc/ecs/ecs.config
#                                     EOF
# }