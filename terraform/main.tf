terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "bedrock-state-mileycent-3682" # Ensure this matches your unique S3 bucket name
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table" # Prevents parallel run conflicts in GitHub Actions
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}