# ==========================================
# 1. IAM ROLES FOR EKS
# ==========================================

# Cluster Control Plane Role
resource "aws_iam_role" "eks_cluster" {
  name = "project-bedrock-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role_name  = aws_iam_role.eks_cluster.name
}

# Worker Node Group Role
resource "aws_iam_role" "eks_nodes" {
  name = "project-bedrock-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role_name  = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role_name  = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role_name  = aws_iam_role.eks_nodes.name
}

# ==========================================
# 2. EKS CLUSTER CONFIGURATION
# ==========================================

resource "aws_eks_cluster" "bedrock" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  # Fixed: Enforces authentication mode to allow access entries
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# ==========================================
# 3. MANAGED NODE GROUPS
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

  update_config {
    max_unavailable = 1
  }

  instance_types = ["t3.medium"]
  ami_type       = "AL2_x86_64"

  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only,
  ]
}

# ==========================================
# 4. EKS ACCESS ENTRIES
# ==========================================

resource "aws_eks_access_entry" "dev_view_entry" {
  cluster_name      = aws_eks_cluster.bedrock.name
  principal_arn     = "arn:aws:iam::336879875316:user/bedrock-dev-view"
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "dev_view_policy" {
  cluster_name  = aws_eks_cluster.bedrock.name
  principal_arn = aws_eks_access_entry.dev_view_entry.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewerPolicy"

  access_scope {
    type = "cluster"
  }
}