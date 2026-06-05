data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Main VPC Configuration
resource "aws_vpc" "bedrock_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "project-bedrock-vpc"
  }
}

# 2. Internet Gateway for Public Internet Access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.bedrock_vpc.id

  tags = {
    Name = "project-bedrock-igw"
  }
}

# 3. Public Subnets (Across 2 Availability Zones)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.bedrock_vpc.id
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "project-bedrock-public-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/role/elb" = "1" # Crucial tag for Public Load Balancers
  }
}

# 4. Private Subnets for EKS Worker Nodes
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.bedrock_vpc.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                              = "project-bedrock-private-${data.aws_availability_zones.available.names[count.index]}"
    "kubernetes.io/role/internal-elb" = "1" # Crucial tag for Private/Internal Load Balancers
  }
}

# 5. Dedicated Subnets for Managed Databases (RDS)
resource "aws_subnet" "database" {
  count             = 2
  vpc_id            = aws_vpc.bedrock_vpc.id
  cidr_block        = "10.0.${count.index + 20}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "project-bedrock-db-${data.aws_availability_zones.available.names[count.index]}"
  }
}

# 6. NAT Gateway Infrastructure (Enables private nodes to reach out to the internet)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "project-bedrock-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Placed inside the first public subnet

  tags = {
    Name = "project-bedrock-nat-gw"
  }

  depends_on = [aws_internet_gateway.igw]
}

# 7. Route Tables & Route Table Associations
# Public Route Table (Routes via Internet Gateway)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.bedrock_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "project-bedrock-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private & Database Route Table (Routes via NAT Gateway)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.bedrock_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "project-bedrock-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = 2
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private.id
}

# 8. RDS Subnet Group (Combines DB subnets for Amazon RDS deployment)
resource "aws_db_subnet_group" "rds" {
  name       = "project-bedrock-rds-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "project-bedrock-rds-subnet-group"
  }
}