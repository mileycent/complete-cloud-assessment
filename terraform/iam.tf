# ==========================================
# 1. DEVELOPER ACCESS (bedrock-dev-view)
# ==========================================

# Create the IAM User for grading/development
resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"
}

# Attach AWS Console ReadOnlyAccess Managed Policy
resource "aws_iam_user_policy_attachment" "dev_console_read" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Generate programmatic access keys (Required for your Grading Credentials deliverable)
resource "aws_iam_access_key" "dev_view_keys" {
  user = aws_iam_user.dev_view.name
}


# ==========================================
# 2. EKS CONTROL PLANE ROLE
# ==========================================

# Assume Role Policy for EKS Service
data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "project-bedrock-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

# Attach standard EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# ==========================================
# 3. EKS NODE GROUP ROLE
# ==========================================

# Assume Role Policy for EC2 Worker Nodes
data "aws_iam_policy_document" "nodes_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "project-bedrock-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.nodes_assume_role.json
}

# Required Policies for EKS Worker Nodes to function properly
resource "aws_iam_role_policy_attachment" "nodes_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}