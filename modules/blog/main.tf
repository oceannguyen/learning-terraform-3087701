module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name          = "ocean-aws-for-all-vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["ap-southeast-1a", "ap-southeast-1b"] # Specify your availability zones

  enable_ipv6 = true

  public_subnets  = ["192.168.0.0/22", "192.168.4.0/22"]  # Public subnets
  private_subnets = ["192.168.8.0/22", "192.168.12.0/22"]  # Private subnets

  tags = {
    Name = "ocean-aws-for-all-vpc"
  }

}

# Create an Egress-Only Internet Gateway for IPv6
resource "aws_egress_only_internet_gateway" "engress_only" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "ocean-aws-egress-only-gateway"
  }
}