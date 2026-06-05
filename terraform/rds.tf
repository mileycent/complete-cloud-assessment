# ==========================================
# 1. DATABASE FIREWALL (SECURITY GROUPS)
# ==========================================

resource "aws_security_group" "db_sg" {
  name        = "project-bedrock-db-sg"
  description = "Restrict access to managed relational database backends"
  vpc_id      = aws_vpc.bedrock_vpc.id # Fixed: Points to your real VPC name

  ingress {
    description     = "Allow MySQL incoming queries from EKS workers"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.bedrock.vpc_config[0].cluster_security_group_id]
  }

  ingress {
    description     = "Allow PostgreSQL incoming queries from EKS workers"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_eks_cluster.bedrock.vpc_config[0].cluster_security_group_id]
  }

  egress {
    description = "Allow unrestricted outbound calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "project-bedrock-database-security-group" }
}

# ==========================================
# 2. DATABASE INSTANCES (MYSQL & POSTGRES)
# ==========================================

# MySQL Core
resource "aws_db_instance" "mysql_db" {
  identifier             = "bedrock-mysql-instance"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "retail_store"
  username               = "db_admin"
  password               = "BedrockSecurePass2026!" 
  db_subnet_group_name   = aws_db_subnet_group.rds.name # Fixed: Uses group from vpc.tf
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Name = "project-bedrock-mysql" }
}

# PostgreSQL Core
resource "aws_db_instance" "postgres_db" {
  identifier             = "bedrock-postgres-instance"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "order_management"
  username               = "postgres_admin"
  password               = "BedrockSecurePass2026!"
  db_subnet_group_name   = aws_db_subnet_group.rds.name # Fixed: Uses group from vpc.tf
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = true

  tags = { Name = "project-bedrock-postgres" }
}