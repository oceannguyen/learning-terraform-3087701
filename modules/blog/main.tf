module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"  # Specified version

  name          = "ocean-aws-for-all-vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["us-east-1a", "us-east-1b"]  # Specify your availability zones
  enable_ipv6   = true
  assign_generated_ipv6_cidr_block = true

  private_subnets = [
    "192.168.0.0/22",  # First private subnet
    "192.168.4.0/22"   # Second private subnet
  ]

  public_subnets = [
    "192.168.8.0/22",  # First public subnet
    "192.168.12.0/22"  # Second public subnet
  ]

  tags = {
    Name = "ocean-aws-for-all-vpc"
  }
}

resource "aws_egress_only_internet_gateway" "egw" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "egress-only-internet-gateway"
  }
}