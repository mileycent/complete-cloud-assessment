# ==========================================
# 1. EKS CONTROL PLANE CONFIGURATION
# ==========================================

resource "aws_eks_cluster" "bedrock" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34" # Explicitly utilizing v1.34.0+ per core requirements

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Requirement 4.4: Control Plane Logging explicitly enabled
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}


# ==========================================
# 2. EKS MANAGED NODE GROUP
# ==========================================

resource "aws_eks_node_group" "bedrock_nodes" {
  cluster_name    = aws_eks_cluster.bedrock.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["t3.medium"] # Solid baseline for running microservices + message brokers

  depends_on = [
    aws_iam_role_policy_attachment.nodes_worker_policy,
    aws_iam_role_policy_attachment.nodes_cni_policy,
    aws_iam_role_policy_attachment.nodes_ecr_policy
  ]
}


# ==========================================
# 3. SECURE DEVELOPER ACCESS ENTRY (RBAC)
# ==========================================

# Create an EKS Access Entry linking the cluster to the IAM Dev User
resource "aws_eks_access_entry" "dev_view_entry" {
  cluster_name  = aws_eks_cluster.bedrock.name
  principal_arn = aws_iam_user.dev_view.arn
  type          = "STANDARD"
}

# Bind the Access Entry to the native Kubernetes "view" cluster role
resource "aws_eks_access_policy_association" "dev_view_policy" {
  cluster_name  = aws_eks_cluster.bedrock.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewerPolicy"
  principal_arn = aws_iam_user.dev_view.arn

  access_scope {
    type = "cluster"
  }
}