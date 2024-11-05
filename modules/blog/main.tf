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
  subnet_id = aws_subnet.awsforall_private_subnet_2.id
  route_table_id = aws_route_table.awsforall_public_r1.id
}

# Security Group to Allow HTTP and SSH Traffic
resource "aws_security_group" "awsforall_web_sg" {
  name        = "awsforall_web_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = aws_vpc.awsforall_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0 
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # allow all outbound traffic, including responses on ephemeral ports.
  }

  tags = {
    Name = "awsforall_web_sg"
  }
}

# Data source to get the latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon's official AMIs for Amazon Linux

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# EC2 Instance Configuration
resource "aws_instance" "awsforall_web_server" {
  ami           = data.aws_ami.amazon_linux.id # Use an appropriate AMI ID for your region
  instance_type = "t2.micro"

  subnet_id               = aws_subnet.awsforall_public_subnet_1.id
  vpc_security_group_ids  = [aws_security_group.awsforall_web_sg.id]

  associate_public_ip_address = true

  user_data                   = <<-EOF
                                  #!/bin/bash
                                  sudo yum update
                                  yum update -y
                                  sudo amazon-linux-extras install nginx1 -y
                                  echo "<h1>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h1>" > /usr/share/nginx/html/index.html
                                  systemctl start nginx
                                  systemctl enable nginx
                                  EOF

  tags = {
    Name = "awsforall_web-server"
  }
}

