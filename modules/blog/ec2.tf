# Data source to get the latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"] # Amazon's official AMIs for Amazon Linux

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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
