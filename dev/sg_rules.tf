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