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

# Create an ALB
resource "aws_lb" "awsforall_alb" {
  name                = "awsforall-alb"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.awsforall_web_sg.id]
  subnets             = [
    aws_subnet.awsforall_public_subnet_1.id,
    aws_subnet.awsforall_public_subnet_2.id
  ]

  enable_deletion_protection = false

  tags = {
    Name = "awsforall-alb"
  }
}

# Next, create a target group for your EC2 instances.
resource "aws_lb_target_group" "awsforall_target_group" {
  name      = "awsforall-target-group"
  port      = 80
  protocol  = "HTTP"
  vpc_id    = aws_vpc.awsforall_vpc.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    protocol            = "HTTP"
  }

  tags = {
    Name = "awsforall-target-group"
  }
}

resource "aws_lb_listener" "awsforall_listener" {
  load_balancer_arn = aws_lb.awsforall_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.awsforall_target_group.arn
  }
}

# Launch Configuration for Auto Scaling Group
resource "aws_launch_template" "awsforall_web_server_lt" {
  name          = "awsforall_web_server_lt"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  # Move vpc_security_group_ids inside network_interfaces block
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.awsforall_web_sg.id]
  }

  user_data  = base64encode(<<-EOF
                                  #!/bin/bash
                                  sudo yum update
                                  yum update -y
                                  sudo amazon-linux-extras install nginx1 -y
                                  echo "<h1>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</h1>" > /usr/share/nginx/html/index.html
                                  systemctl start nginx
                                  systemctl enable nginx
                                  EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "awsforall_asg" {
  desired_capacity  = 2
  max_size          = 5
  min_size          = 1

  launch_template {
    id      = aws_launch_template.awsforall_web_server_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = [
    aws_subnet.awsforall_public_subnet_1.id,
    aws_subnet.awsforall_public_subnet_2.id,
  ]

  target_group_arns = [ aws_lb_target_group.awsforall_target_group.arn ]


  tag {
    key                 = "Name"
    value               = "awsforall_asg"
    propagate_at_launch = true
  }
}


