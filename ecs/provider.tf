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

  # Optional: Default tags that will be applied to all resources
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

