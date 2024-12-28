# ECS Fargate Deployment with Terraform and GitLab CI/CD

## Table of Contents
1. [Overview](#overview)
2. [Project Architecture](#project-architecture)
3. [Getting Started](#getting-started)
4. [Modules](#modules)
   - [Terraform Backend](#terraform-backend)
   - [Networking](#networking)
   - [ECS Infrastructure Overview](#ecs-infrastructure)
      - [ECS Configuration](#ecs-configuration)
      - [ALB Configuration](#alb-configuration)
      - [ECR Configuration](#ecr-configuration) (have to create manually to push the docker image first)
      - [ACM Configuration](#acm-configuration)
      - [Route53 Configuration](#route53-configuration)
      - [IAM Permissions](#iam-roles-and-policies-for-ecs-tasks)
      - [Security Groups](#security-groups-configuration)
      - [Provider and Backend Configuration](#provider-and-backend-configuration)
      - [terraform.tfvars](#terraform-tfvars)
5. [GitLab CI/CD Setup](#gitlab-cicd-setup)
      - [Create an IAM user account for GitLab CI/CD](#gitlab-iam-user)
      - [Set up CI/CD Pipelines](#pipelines-setup)


6. [Application Details](#application-details)
      - [Python application](#python-application)
      - [Dockerfile](#dockerfile)
7. [Additional Notes](#additional-notes)

---

## Overview
This project automates the deployment of a containerized Python application on **AWS ECS Fargate** using **Terraform** for infrastructure provisioning and **GitLab CI/CD** for continuous integration and delivery.

### Key Features
- **Modular Terraform Setup**: Backend, networking, and ECS modules for scalability.
- **CI/CD Pipeline**: Automates Docker image build, push to ECR, and deployment to ECS.
- **Dev and Prod Environments**: Isolated environments with dedicated ALB configurations.
- **TLS Support**: Secure HTTPS setup using ACM and Route 53.

---

## Project Architecture
![Project Architecture](images/architecture_diagram.png)

---

## Getting Started

### Prerequisites
- **AWS CLI** installed and configured.
- **Terraform** (>= 1.6.0).
- **GitLab Account** with necessary permissions.
- **Docker** installed locally for testing builds.

### Steps
1. Clone the repository:
```bash
git clone https://github.com/sahibgasimov/ecs-gitlab-terraform.git

cd ecs-gitlab-terraform
```

### Modules

```tree
├── backend/           # Terraform backend module
├── networking/        # VPC and networking module
├── ecs/               # ECS cluster and services module
├── gitlab_cicd/       # Gitlab pipeline file 
├── images/            # Architecture and CI/CD images
├── app/               # Python application code
├── .gitlab-ci.yml     # GitLab CI/CD pipeline
└── README.md          # Project documentation
```

### Terraform Backend

This repository contains a Terraform configuration to manage state files and locking using AWS S3 and DynamoDB. It sets up an S3 bucket for state file storage and a DynamoDB table for state locking.

---

#### Features

- **S3 Bucket**: Stores the Terraform state file.
  - Versioning is enabled for safety.
  - Configured to allow state storage with high reliability.
- **DynamoDB Table**: Provides state locking to prevent race conditions in multi-user environments.

---

### How It Works

1. **Manual S3 Bucket Creation**:
   - Before running Terraform, create the S3 bucket manually to ensure the bucket is not accidentally destroyed by Terraform.

2. **Local to Remote State Migration**:
   - Initially, the state is stored locally. After running Terraform to create required resources (S3 and DynamoDB), the backend is updated to use the S3 bucket for remote state storage.

## Installation and Usage

### Step 1: Initialize and Apply Configuration with Local Backend

1. Clone the repository:
```git
git clone https://github.com/sahibgasimov/ecs-gitlab-terraform.git
cd backend
```
Initialize Terraform:

```hcl
terraform init
terraform apply
```

### Step 2: Configure Remote Backend with S3
Uncomment the following block in main.tf and run terraform apply to create backend module. Once created update your existing s3 bucket to migrate state file to s3 bucket. 

```
terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-prod"  # Replace with your S3 bucket name
    key            = "backend/terraform.tfstate"      
    region         = "us-east-1"                      
    dynamodb_table = "my-project-terraform-lock"       
    encrypt        = true
  }
}
```
 

Migrate the state file to the S3 backend:

```hcl
terraform init -migrate-state
```

![alt text](images/terraform_state_backend.jpg)

#### File Structure
```

├── main.tf             # Main configuration file
├── variables.tf        # Input variables
├── terraform.tfvars    # Variable values
├── outputs.tf          # Outputs for debug and reference
├── README.md           # Project documentation
```


#### Notes
- Create S3 remote state bucket manually to prevent accidental deletion.
- The backend configuration uses versioning for safety and state locking for consistency.
- Dynamodb table locks Terraform state files to prevent concurrent modifications.

### Networking

#### VPC Module for ECS Cluster

This module configures an AWS Virtual Private Cloud (VPC) for the ECS cluster, including private and public subnets, NAT gateway routes for private subnet, and internet gateway for public subnet.

---

![alt text](images/image.png)

## Features

- **VPC Creation**:
  - CIDR block: `10.0.0.0/16`
  - Public and private subnets across availability zones.
- **NAT Gateway**:
  - Enabled for outbound internet access from private subnets.
- **Internet Gateway**
  - Enabled for outbound internet access from public subnets.

---

## Prerequisites

- Ensure the backend S3 bucket and DynamoDB table for Terraform state are already configured. Check Backend module for the steps above.
- AWS credentials must be set up for the specified region.

---

## File Structure

```plaintext
.
├── main.tf             # Defines the VPC module and its configurations
├── provider.tf         # Configures the AWS provider and backend
├── variables.tf        # Declares input variables
├── terraform.tfvars    # Defines variable values
├── outputs.tf          # Exports outputs such as subnet and VPC IDs  

```
### Usage

```
terraform init
terraform apply
```

![alt text](images/terraform_plan.png)

### Notes
- The terraform-aws-modules/vpc module is used to simplify VPC creation.
- Ensure availability zones in your region support the configuration.
- Update main.tf with CIDR block and subnet details if necessary.

### ECS Infrastructure

### ECS Configuration

ECS Cluster has two ECS services with two task definitions for dev and prod. Application is listening on port 8080. 


```hcl
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

######## ECS SERVICE ##########
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


######### ECS TASK DEFINITION ###########

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


```

### ALB Configuration

The Application Load Balancer (ALB) manages traffic routing to ECS services based on the environment (dev or prod). There are two target groups dev and prod, listening on ecs task definition containers port 8080. There are two listeners port 443/https and 80/http permanent redirection to https. 

```hcl
resource "aws_lb" "app_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.sg_alb.security_group_id]
  subnets            = local.public_subnets

  enable_deletion_protection = false

  tags = {
    Project = var.app_name
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.app_certificate_validation.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "dev_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    host_header {
      values = [var.alb_hostname_dev]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dev_target_group.arn
  }
}

resource "aws_lb_listener_rule" "prod_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200

  condition {
    host_header {
      values = [var.alb_hostname_prod]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prod_target_group.arn
  }
}


resource "aws_lb_target_group" "dev_target_group" {
  name        = "${var.app_name}-dev-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Environment = var.env_name_dev
    Project     = var.app_name
  }
}

resource "aws_lb_target_group" "prod_target_group" {
  name        = "${var.app_name}-prod-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc.vpc_id

  health_check {
    path                = "/api/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Environment = var.env_name_prod
    Project     = var.app_name
  }
}
```

### ECR Configuration

For this demo tutorial I have to create ECR manually since we have to push the docker image to ECR before we create ECS task definition deployment. I do however included ECR configuration in the ecr.tf file, you can alwaus import the resource with terraform import command.

### ACM Configuration

ACM certificate is needed for ALB validation with Route53 domain for https connection. Terraform will automatically create necessary CNAME records for ACM validation.

```hcl
resource "aws_acm_certificate" "app_certificate" {
  domain_name       = var.alb_hostname_prod # Use prod domain for ACM validation
  validation_method = "DNS"

  subject_alternative_names = [
    var.alb_hostname_dev # Add dev domain as SAN
  ]

  tags = {
    Environment = var.env_name_prod
    Project     = var.app_name
  }
}

resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.app_certificate.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 300
}

resource "aws_acm_certificate_validation" "app_certificate_validation" {
  certificate_arn         = aws_acm_certificate.app_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}

```

### Route53 Configuration

Two records will be created one for dev and one for prod domain. You can specify domain names and hostedzone in terraform.tfvars file.

```hcl

resource "aws_route53_record" "dev_record" {
  zone_id = var.route53_zone_id
  name    = var.alb_hostname_dev
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "prod_record" {
  zone_id = var.route53_zone_id
  name    = var.alb_hostname_prod
  type    = "A"

  alias {
    name                   = aws_lb.app_alb.dns_name
    zone_id                = aws_lb.app_alb.zone_id
    evaluate_target_health = true
  }
}

```


### IAM Roles and Policies for ECS Tasks

### 1. Execution Role
#### Role: `aws_iam_role.ecs_task_execution_role`

#### Permissions
1. **Pull Docker images from ECR**  
   - `ecr:GetDownloadUrlForLayer`
   - `ecr:BatchGetImage`
   - `ecr:BatchCheckLayerAvailability`
2. **Write logs to CloudWatch Logs**  
   - `logs:PutLogEvents`
   - `logs:CreateLogStream`
3. **Access SSM Parameters**  
   - `ssm:GetParameters`
   - `ssm:GetParameter`
   - `ssm:GetParameterHistory`

#### Purpose
- Pull container images from ECR.
- Enable centralized monitoring via CloudWatch Logs.
- Fetch configuration parameters from SSM Parameter Store.

### Policy: `ecs_task_execution_policy`
Combines minimal permissions required for:
- ECR image pulls.
- CloudWatch Logs writing.
- SSM Parameter access.  

---

### 2. Task Role: `aws_iam_role.ecs_task_role`
This role allows ECS tasks to perform application-specific operations.

#### Permissions
1. **Access S3 Buckets**  
   - `s3:ListBucket`
   - `s3:GetObject`
2. **Fetch secrets from Secrets Manager**  
   - `secretsmanager:GetSecretValue`
3. **Write logs to CloudWatch Logs**  
   - `logs:PutLogEvents`
   - `logs:CreateLogStream`

#### Purpose
- Access S3 resources for fetching required files.
- Retrieve sensitive application credentials securely from AWS Secrets Manager (if required).
- Log application activity to CloudWatch Logs.

### Policy: `ecs_task_custom_policy`
Custom policy with fine-grained permissions for:
- S3 bucket operations.
- Secrets Manager access.
- Application-level logging to CloudWatch Logs.


```hcl
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
```

### 3. IAM User gitlab-cicd

This user will be used for setting up GitLab CICD Pipelines. Access and Secret keys will be stored in Parameters Store you will need once we start setting up pipelines. User will have these two policies assigned AmazonEC2ContainerRegistryPowerUser and AmazonECS_FullAccess

```hcl

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
```
---


### Security Groups Configuration

This Terraform configuration sets up security groups for an Application Load Balancer (ALB) and ECS tasks in both development and production environments using the `terraform-aws-modules/security-group` module.

### Overview

- **ALB Security Group**:
  - Allows inbound HTTP (port 80) and HTTPS (port 443) traffic from anywhere.
  - Allows all outbound traffic.

- **ECS Tasks (Dev and Prod) Security Groups**:
  - Allow inbound traffic on port 8080 **from the ALB security group**.
  - Allow all outbound traffic.
  - Separate security groups for development  and production services.

###

```hcl
# Security Group for ALB
module "sg_alb" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-alb"
  description = "Security group for ALB"
  vpc_id      = local.vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${var.app_name}-alb"
  }
}

# Security Group for ECS Tasks (Dev)
module "sg_ecs_dev" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-dev-ecs"
  description = "Security group for ECS tasks (Dev)"
  vpc_id      = local.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.sg_alb.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${var.app_name}-dev-ecs"
  }
}

# Security Group for ECS Tasks (Prod)
module "sg_ecs_prod" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.app_name}-prod-ecs"
  description = "Security group for ECS tasks (Prod)"
  vpc_id      = local.vpc.vpc_id

  ingress_with_source_security_group_id = [
    {
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      source_security_group_id = module.sg_alb.security_group_id
    }
  ]

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name = "${var.app_name}-prod-ecs"
  }
}
```

### Provider and Backend Configuration

This Terraform configuration sets up the foundational settings for managing AWS infrastructure, including backend state management and required providers.


#### Required Version
- **Terraform**: `>= 1.6.0`

#### Providers
- **AWS**: `~> 5.73.0`
- **Random**: `~> 3.6.0`

#### Backend Configuration
The state file is stored in an S3 bucket for secure and centralized management. State locking is enabled using DynamoDB. We will be using the s3 bucket that we configured in earlier from Backend module.

- **S3 Bucket**: `my-project-terraform-state-prod` (replace with your bucket name)
- **State File Key**: `ecs/terraform.tfstate`
- **Region**: `us-east-1` (replace with your AWS region)
- **DynamoDB Table**: `my-project-terraform-lock` (replace with your table name)
- **Encryption**: Enabled

#### AWS Provider Configuration
- **Region**: Configured dynamically using `var.region`.
- **Default Tags**: Optional feature to apply tags to all resources (to be configured as needed).

#### Remote State Data Source
- Pulls the networking state from a remote S3 bucket.
  - **Bucket**: `my-project-terraform-state-prod` (replace with your bucket name)
  - **State File Key**: `networking/terraform.tfstate`
  - **Region**: `us-east-1`
  - **DynamoDB Table**: `my-project-terraform-lock`
  - **Encryption**: Enabled

### Key Highlights
- **Remote State Management**: Ensures infrastructure consistency across teams by using a centralized state file.
- **State Locking**: Prevents concurrent modifications using DynamoDB.
- **Modular Design**: Enables seamless integration with other infrastructure components via remote state.

Replace placeholders with your project-specific details for production use.


```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.73.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }

  backend "s3" {
    bucket         = "my-project-terraform-state-prod" # Replace with your S3 bucket name
    key            = "ecs/terraform.tfstate"           # Unique key for ECS state file
    region         = "us-east-1"                       # Replace with your AWS region
    dynamodb_table = "my-project-terraform-lock"       # Replace with your DynamoDB table name
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket         = "my-project-terraform-state-prod" # Replace with your S3 bucket name
    key            = "networking/terraform.tfstate"    # Path to the networking state file
    region         = "us-east-1"                       # Replace with your AWS region
    dynamodb_table = "my-project-terraform-lock"       # Replace with your DynamoDB table name
    encrypt        = true
  }
}

```

### terraform.tfvars

#### Environment and Region Configuration


- **Environment Names**:
  - Development: `dev`
  - Production: `prod`
- **AWS Region**: `us-east-1` (update if using a different region)

### Application Details
- **Application Name**: `web-app`

### AWS Account Details
- **Account ID**: `123456789` (update with your AWS account ID)

### ALB Configuration
- **Development ALB Hostname**: `web-app-dev.123456789.example.net`
- **Production ALB Hostname**: `web-app-prod.123456789.example.net`

### DNS
- **Route 53 Hosted Zone ID**: `ZSDFSDF3FDSSDFSDFDF` (update as per your hosted zone)

###
```hcl
# Environment and Region
env_name_prod = "prod"
env_name_dev  = "dev"       # Change to "prod" for production
region        = "us-east-1" # AWS region

# Application Details
app_name = "web-app" # Your application name

# AWS Account Details
account_id = "452303021915" # Your AWS account ID

# ALB Configuration
alb_hostname_dev  = "web-app-dev.452303021915.realhandsonlabs.net"
alb_hostname_prod = "web-app-prod.452303021915.realhandsonlabs.net"

# Subnet and VPC IDs

route53_zone_id = "Z10075723METSXT8WC4VB"
```

## Gitlab CI/CD Setup

We will build a GitLab CI/CD pipeline from scratch to automate deployments to AWS ECS Fargate utilizing Docker containers, AWS ECR for image storage, and GitLab YAML for configuration.

Pipeline Structure: Two branches (dev and prod)  define the target ECS service/task based on the ECS service name and deploy the application.
Stages: Automate validation, build, push, and deployment through defined CI/CD stages.

- GitLab AWS IAM User
- GitLab Project 
- Setup branch dev and main protection
- Setup GitLab CICD Pipelines

### GitLab IAM user

Terraform will create an IAM user and store IAM acccess and secret credentials for 'gitlab-cicd' user. We will need to retrieve IAM access and sercret keys from SSM Parameters Store.  This user doesn't need programmatic but terminal access only. 

![alt text](images/gitlab_cicd.png)
![alt text](images/parameters_store.png)

Log in to your Gitlab account and create a new project 

![alt text](images/new_project.png)

Log in to your linux server and git initialize new repository 

![alt text](images/git_pull.png)

You will need to have two branches  'dev' and 'main':
![alt text](images/branches.png)

Protect both of your  branch from deletion as well as push without merge

![alt text](images/protect_branches.png)

Set 3 variables for your pipeline 
![alt text](images/variables.png)

![alt text](images/three_variables.png)

### Pipelines setup
##

![alt text](images/gitlabcicdyaml.png)

## .gitlab-ci.yml

```yaml
stages:
    - validate_environment
    - build_and_publish
    - deploy_to_dev
    - deploy_to_production    
    - finalize_pipeline

workflow:  # Trigger pipeline only for specific branches
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
    - if: '$CI_COMMIT_BRANCH == "dev"'

image: registry.gitlab.com/gitlab-org/cloud-deploy/aws-base:latest

variables:
  AWS_ACCOUNT_NUMBER : "452303021915"
  REGION             : "us-east-1"
  IMAGE_REPOSITORY   : "web-app-repository"
  CLUSTER_NAME       : "web-app-cluster"

  DEV_SERVICE_NAME   : "web-app-dev"
  DEV_TASK_NAME      : "web-app-dev"

  PROD_SERVICE_NAME  : "web-app-prod"
  PROD_TASK_NAME     : "web-app-prod"

test_environment:
  stage: validate_environment
  script:
    - echo "Validating environment setup..."
    - aws --version
    - docker --version
    - jq --version
    - aws sts get-caller-identity  

build_and_push:
  stage: build_and_publish
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375  
  before_script:
   - aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com

  script:
    - echo "Building the Docker image..."
    - docker build -t $IMAGE_REPOSITORY .
    - echo "Tagging the image..."
    - docker tag $IMAGE_REPOSITORY:latest $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$IMAGE_REPOSITORY:$CI_COMMIT_BRANCH-latest
    - docker tag $IMAGE_REPOSITORY:latest $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$IMAGE_REPOSITORY:$CI_COMMIT_BRANCH-$CI_COMMIT_SHORT_SHA
    - echo "Pushing the image to ECR..."
    - docker push $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$IMAGE_REPOSITORY:$CI_COMMIT_BRANCH-latest
    - docker push $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$IMAGE_REPOSITORY:$CI_COMMIT_BRANCH-$CI_COMMIT_SHORT_SHA

deploy_to_dev:
  stage: deploy_to_dev
  rules:
    - if: '$CI_COMMIT_BRANCH == "dev"'
  script:
    - echo "Deploying to development environment..."
    - |
      aws ecs update-service \
        --cluster         $CLUSTER_NAME \
        --service         $DEV_SERVICE_NAME \
        --task-definition $DEV_TASK_NAME \
        --force-new-deployment

deploy_to_production:
  stage: deploy_to_production
  when: manual                                  # Require manual confirmation for production
  manual_confirmation: 'Proceed with production deployment?' 
  allow_failure: false                          # Must succeed to continue
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
  script:
    - echo "Deploying to production environment..."
    - |
      aws ecs update-service \
        --cluster         $CLUSTER_NAME \
        --service         $PROD_SERVICE_NAME \
        --task-definition $PROD_TASK_NAME \
        --force-new-deployment        

finalize_pipeline:
  stage: finalize_pipeline
  script:
    - echo "CI/CD Pipeline completed successfully!"
```


## Python application 

Small Python application for converting image to pdf.

app.py

```python
from flask import Flask, request, send_file, jsonify
from PIL import Image
import os

app = Flask(__name__)
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'output'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

@app.route('/')
def home():
    return '''
    <!doctype html>
    <title>Image to PDF Converter</title>
    <h1>Upload an image to convert to PDF</h1>
    <form method="post" action="/convert" enctype="multipart/form-data">
        <input type="file" name="image" accept="image/*">
        <button type="submit">Convert to PDF</button>
    </form>
    '''

@app.route('/convert', methods=['POST'])
def convert_to_pdf():
    if 'image' not in request.files:
        return "No file uploaded", 400
    
    file = request.files['image']
    if file.filename == '':
        return "No selected file", 400

    try:
        # Save the uploaded file
        image_path = os.path.join(UPLOAD_FOLDER, file.filename)
        file.save(image_path)

        # Convert to PDF
        image = Image.open(image_path)
        if image.mode != 'RGB':
            image = image.convert('RGB')
        pdf_path = os.path.join(OUTPUT_FOLDER, f"{os.path.splitext(file.filename)[0]}.pdf")
        image.save(pdf_path, "PDF")

        # Send the PDF file as a response
        return send_file(pdf_path, as_attachment=True)
    except Exception as e:
        return f"An error occurred: {e}", 500

# Health check endpoint for ALB
@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)

```

### Dockerfile

 

```Dockerfile
# Use an official Python runtime as the base image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the application code and requirements into the container
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 8080 for the Flask application
EXPOSE 8080

# Run the Flask application
CMD ["python", "app.py"]

```

