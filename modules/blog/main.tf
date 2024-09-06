module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name          = "ocean-aws-for-all-vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["us-east-1a", "us-east-1b"] # Specify your availability zones

  enable_ipv6 = true
  ipv6_cidr_block = "2600:1f14:abcd:1234::/64"  # Example IPv6 CIDR block

  public_subnets  = ["192.168.0.0/22", "192.168.4.0/22"]  # Public subnets
  private_subnets = ["192.168.8.0/22", "192.168.12.0/22"]  # Private subnets

  tags = {
    Name = "ocean-aws-for-all-vpc"
  }

   # Enable Egress-Only Internet Gateway for IPv6
  enable_egress_only_internet_gateway = true
}