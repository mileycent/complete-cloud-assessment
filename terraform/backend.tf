terraform {
  backend "s3" {
    bucket         = "project-bedrock-tfstate-storage" # Change to a unique bucket name
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "project-bedrock-tflocks"        # Partition key must be 'LockID'
    encrypt        = true
  }
}