# ==========================================
# 1. EKS CLUSTER CONFIGURATION
# ==========================================

resource "aws_eks_cluster" "bedrock" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster.arn # References your role from iam.tf
  version  = "1.34"                       # Fixed: Matches your running cluster version

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Enforces modern authentication mode to allow API access entries
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# ==========================================
# 2. MANAGED NODE GROUPS
# ==========================================

resource "aws_eks_node_group" "bedrock_nodes" {
  cluster_name    = aws_eks_cluster.bedrock.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn # References your role from iam.tf
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"
}

# ==========================================
# 3. EKS ACCESS ENTRIES (RBAC)
# ==========================================

resource "aws_eks_access_entry" "dev_view_entry" {
  cluster_name  = aws_eks_cluster.bedrock.name
  principal_arn = "arn:aws:iam::336879875316:user/bedrock-dev-view"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "dev_view_policy" {
  cluster_name  = aws_eks_cluster.bedrock.name
  principal_arn = aws_eks_access_entry.dev_view_entry.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewerPolicy"

  access_scope {
    type = "cluster"
  }
}