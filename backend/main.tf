terraform {
  required_version = ">= 1.6.0, < 2.0.0" 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.35.0" 
    }
  }
}

provider "aws" {
  region = var.region
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 3.0" 

  bucket        = "${var.project_name}-terraform-state-${var.environment}"
  acl           = null
  force_destroy = true

  versioning = {
    enabled = true
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

module "dynamodb_table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "~> 2.0" 

  name         = "${var.project_name}-terraform-lock"
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "LockID"
      type = "S"
    }
  ]

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

#First run tf apply to create with local backend then uncomment and move your local backend to the s3 
terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-prod"  # Replace with created S3 bucket name
    key            = "backend/terraform.tfstate"       # Unique key for this module's state file
    region         = "us-east-1"                       # Replace with your AWS region
    dynamodb_table = "my-project-terraform-lock"       # Replace with created DynamoDB table name
    encrypt        = true
  }
}

# resource "aws_s3_bucket" "my-project-terraform-state-prod" {
#   bucket = "my-project-terraform-state-prod"  

#   tags = {
#     Name        = "MyBucket"
#     Environment = "Dev"
#   }
# }

# Optional: Add versioning
# resource "aws_s3_bucket_versioning" "my-project-terraform-state-prod" {
#   bucket = aws_s3_bucket.my-project-terraform-state-prod.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }