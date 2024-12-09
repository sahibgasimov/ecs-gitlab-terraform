resource "aws_iam_role" "ecs_task_execution_role" {
  name        = "${var.app_name}-task-execution"
  description = "Allows ECS tasks to call AWS services on your behalf"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-task-execution"
  }
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "${var.app_name}-execution-policy"
  role = aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParameterHistory",
          "ecr:GetAuthorizationToken"

        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name        = "${var.app_name}-task"
  description = "Allows ECS tasks to assume this role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-task"
  }
}

resource "aws_iam_role_policy" "ecs_task_custom_policy" {
  name = "${var.app_name}-custom-task-policy"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "secretsmanager:GetSecretValue",
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = "*"
      }
    ]
  })
}

##### GitLab CICD user #####



# Create the IAM user
resource "aws_iam_user" "gitlab_cicd" {
  name = "gitlab-cicd"
}

# Attach AmazonEC2ContainerRegistryPowerUser policy
resource "aws_iam_user_policy_attachment" "ecr_power_user" {
  user       = aws_iam_user.gitlab_cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Attach AmazonECS_FullAccess policy
resource "aws_iam_user_policy_attachment" "ecs_full_access" {
  user       = aws_iam_user.gitlab_cicd.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

# Create access keys for the user
resource "aws_iam_access_key" "gitlab_cicd_key" {
  user = aws_iam_user.gitlab_cicd.name
}

# Store Access Key ID in SSM Parameter Store
resource "aws_ssm_parameter" "access_key_id" {
  name        = "/gitlab-cicd/access_key_id"
  description = "Access Key ID for gitlab-cicd user"
  type        = "String"
  value       = aws_iam_access_key.gitlab_cicd_key.id

}

# Store Secret Access Key in SSM Parameter Store
resource "aws_ssm_parameter" "secret_access_key" {
  name        = "/gitlab-cicd/secret_access_key"
  description = "Secret Access Key for gitlab-cicd user"
  type        = "SecureString"
  value       = aws_iam_access_key.gitlab_cicd_key.secret

}
