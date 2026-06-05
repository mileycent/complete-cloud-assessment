terraform {
  backend "s3" {
    bucket         = "bedrock-state-mileycent-3682"
    key            = "state/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}