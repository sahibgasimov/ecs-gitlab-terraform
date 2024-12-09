provider "aws" {
  region = var.region
}
terraform {
  required_version = ">= 1.6.0, < 2.0.0" 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.35.0" 
    }
  }
}

terraform {
  backend "s3" {
    bucket         = "my-project-terraform-state-prod"  # Replace with your actual bucket name
    key            = "networking/terraform.tfstate"    # Unique state file key for networking module
    region         = "us-east-1"                       # Replace with your AWS region
    dynamodb_table = "my-project-terraform-lock"       # Replace with your actual DynamoDB table name
    encrypt        = true
  }
}


