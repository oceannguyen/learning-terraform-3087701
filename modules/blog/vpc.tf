# Create a VPC
resource "aws_vpc" "awsforall_vpc" {
  cidr_block = "192.168.0.0/24"

  tags = {
    Name = "awsforall_vpc"
  }
}

# Create Private Subnets
resource "aws_subnet" "awsforall_private_subnet_1" {
  vpc_id            = aws_vpc.awsforall_vpc.id
  cidr_block        = "192.168.0.0/26"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "awsforall_private_subnet_1"
  }
}

resource "aws_subnet" "awsforall_private_subnet_2" {
  vpc_id            = aws_vpc.awsforall_vpc.id
  cidr_block        = "192.168.0.64/26"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "awsforall_private_subnet_2"
  }
}

# Create Public Subnets
resource "aws_subnet" "awsforall_public_subnet_1" {
  vpc_id            = aws_vpc.awsforall_vpc.id
  cidr_block        = "192.168.0.128/26"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "awsforall_public_subnet_1"
  }
}

resource "aws_subnet" "awsforall_public_subnet_2" {
  vpc_id            = aws_vpc.awsforall_vpc.id
  cidr_block        = "192.168.0.192/26"
  availability_zone = "ap-southeast-1b"

  tags = {
    Name = "awsforall_public_subnet_2"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "awsforall_igw" {
  vpc_id = aws_vpc.awsforall_vpc.id

  tags = {
    Name = "awsforall_igw"
  }
}

# Create a Route Table for Public Subnets
resource "aws_route_table" "awsforall_public_r1" {
  vpc_id = aws_vpc.awsforall_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.awsforall_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Associate Route Table with Public Subnets
resource "aws_route_table_association" "public_association_1" {
  subnet_id = aws_subnet.awsforall_public_subnet_1.id
  route_table_id = aws_route_table.awsforall_public_r1.id
}

resource "aws_route_table_association" "public_association_2" {
  subnet_id = aws_subnet.awsforall_public_subnet_2.id
  route_table_id = aws_route_table.awsforall_public_r1.id
}