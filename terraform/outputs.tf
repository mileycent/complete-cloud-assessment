output "cluster_endpoint" {
  description = "The URL of the EKS Kubernetes API server"
  value       = aws_eks_cluster.bedrock.endpoint
}

output "cluster_name" {
  description = "The exact name of the provisioned EKS Cluster"
  value       = aws_eks_cluster.bedrock.name
}

output "region" {
  description = "The target AWS operational region"
  value       = "us-east-1"
}

output "vpc_id" {
  description = "The ID of the generated project VPC network"
  value       = aws_vpc.bedrock_vpc.id
}

output "assets_bucket_name" {
  description = "The resolved globally unique name of your S3 assets bucket"
  value       = aws_s3_bucket.assets.id
}

# EXTRA GRADING HELPER: Included to help you retrieve your developer credentials easily
output "developer_access_key_id" {
  description = "Programmatic access key for the bedrock-dev-view user"
  value       = aws_iam_access_key.dev_view_keys.id
}

output "developer_secret_access_key" {
  description = "Programmatic secret key for the bedrock-dev-view user (Sensitive)"
  value       = aws_iam_access_key.dev_view_keys.secret
  sensitive   = true
}