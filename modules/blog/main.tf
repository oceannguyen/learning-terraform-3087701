module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"  # Specified version

  name          = "awsforall_vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["ap-southeast-1a", "ap-southeast-1b"]  # Specify your availability zones

  private_subnets = [
    "192.168.0.0/22",  # First private subnet
    "192.168.4.0/22"   # Second private subnet
  ]

  public_subnets = [
    "192.168.8.0/22",  # First public subnet
    "192.168.12.0/22"  # Second public subnet
  ]

  private_subnet_tags = {
    Name = "awsforall_private-subnet"
  }

  public_subnet_tags = {
    Name = "awsforall_public-subnet"
  }

  tags = {
    Name = "awsforall_vpc"
  }
}

resource "aws_security_group" "awsforall_web_sg" {
  name        = "awsforall_web_sg"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = module.vpc.vpc_id

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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "awsforall_web_sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon's official AMIs for Amazon Linux

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "awsforall_web_server" {
  ami           = data.aws_ami.amazon_linux.id # Use an appropriate AMI ID for your region
  instance_type = "t2.micro"

  subnet_id               = module.vpc.public_subnets[0]
  vpc_security_group_ids  = [aws_security_group.awsforall_web_sg.id]

  associate_public_ip_address = true

  user_data                   = <<-EOF
                                  #!/bin/bash
                                  yum update -y
                                  yum install -y nginx
                                  echo "<h1>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h1>" > /usr/share/nginx/html/index.html
                                  systemctl start nginx
                                  systemctl enable nginx
                                  EOF

  tags = {
    Name = "awsforall_web-server"
  }
}

