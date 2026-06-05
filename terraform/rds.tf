# ==========================================
# 1. DATABASE SECURITY GROUPS (Least Privilege)
# ==========================================

resource "aws_security_group" "db_sg" {
  name        = "project-bedrock-db-sg"
  description = "Allow inbound traffic from EKS worker nodes only"
  vpc_id      = aws_vpc.bedrock_vpc.id

  # Inbound MySQL from EKS Nodes
  ingress {
    description     = "MySQL from EKS worker nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_eks_node_group.bedrock_nodes.resources[0].remote_access_security_group_id]
  }

  # Inbound PostgreSQL from EKS Nodes
  ingress {
    description     = "PostgreSQL from EKS worker nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_node_group.bedrock_nodes.resources[0].remote_access_security_group_id]
  }

  # Restrict outbound traffic completely (or modify if external DB sync is required)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project-bedrock-db-sg"
  }
}

# ==========================================
# 2. AMAZON RDS INSTANCES (MySQL & PostgreSQL)
# ==========================================

# RDS MySQL Instance
resource "aws_db_instance" "mysql" {
  identifier             = "bedrock-mysql-db"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro" # Cost-effective for testing/capstone environments
  username               = "retail_admin"
  password               = aws_secretsmanager_secret_version.db_pass_val.secret_string
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "bedrock-mysql-database"
  }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier             = "bedrock-postgres-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  username               = "retail_admin"
  password               = aws_secretsmanager_secret_version.db_pass_val.secret_string
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = {
    Name = "bedrock-postgres-database"
  }
}