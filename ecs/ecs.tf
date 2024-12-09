resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.app_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.app_name}-cluster"
  }

  lifecycle {
    ignore_changes = [setting]
  }
}

resource "aws_ecs_cluster_capacity_providers" "app_cluster_providers" {
  cluster_name = aws_ecs_cluster.app_cluster.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

########ECS SERVICE##########
# ECS Service for Dev
resource "aws_ecs_service" "dev" {
  name            = "${var.app_name}-dev"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.dev.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.sg_ecs_dev.security_group_id]
    subnets          = local.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dev_target_group.arn
    container_name   = "dev-container"
    container_port   = 8080
  }
}

# ECS Service for Prod
resource "aws_ecs_service" "prod" {
  name            = "${var.app_name}-prod"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.prod.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.sg_ecs_prod.security_group_id]
    subnets          = local.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prod_target_group.arn
    container_name   = "prod-container"
    container_port   = 8080
  }
}


######### ECS TASK DEFINITION###########

resource "aws_ecs_task_definition" "dev" {
  family                   = "${var.app_name}-dev"
  container_definitions    = file("${path.module}/container_definitions/web_app_dev.json")
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  tags = {
    Name = "${var.app_name}-dev"
  }
}

resource "aws_ecs_task_definition" "prod" {
  family                   = "${var.app_name}-prod"
  container_definitions    = file("${path.module}/container_definitions/web_app_prod.json")
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  tags = {
    Name = "${var.app_name}-prod"
  }
}
