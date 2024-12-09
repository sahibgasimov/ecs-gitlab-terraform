# Terraform S3 Backend Configuration

This repository contains a Terraform configuration to manage state files and locking using AWS S3 and DynamoDB. It sets up an S3 bucket for state file storage and a DynamoDB table for state locking, ensuring a safe and reliable state management process.

---

## Features

- **S3 Bucket**: Stores the Terraform state file.
  - Versioning is enabled for safety.
  - Configured to allow state storage with high reliability.
- **DynamoDB Table**: Provides state locking to prevent race conditions in multi-user environments.

---

## How It Works

1. **Manual S3 Bucket Creation**:
   - Before running Terraform, create the S3 bucket manually to ensure the bucket is not accidentally destroyed by Terraform.

2. **Local to Remote State Migration**:
   - Initially, the state is stored locally. After running Terraform to create required resources (S3 and DynamoDB), the backend is updated to use the S3 bucket for remote state storage.

3. **Modules**:
   - Uses the `terraform-aws-modules/s3-bucket` module to configure the S3 bucket.
   - Uses the `terraform-aws-modules/dynamodb-table` module to configure the DynamoDB table.

---

## Prerequisites

- AWS credentials should be configured for the specified region.
- Create an S3 bucket manually before applying the Terraform configuration.

---

## Installation and Usage

### Step 1: Initialize and Apply Configuration with Local Backend

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd <repository-directory>
Initialize Terraform:

```
terraform init
terraform apply
```

### Step 2: Configure Remote Backend with S3
Uncomment the following block in main.tf and update the placeholders:

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

```
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




