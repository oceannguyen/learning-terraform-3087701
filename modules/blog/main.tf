module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name          = "ocean-aws-for-all-vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["ap-southeast-1a", "ap-southeast-1b"] # Specify your availability zones

  enable_ipv6                      = true
  assign_generated_ipv6_cidr_block = true  # Automatically assign an IPv6 CIDR block

  public_subnets  = ["192.168.0.0/22", "192.168.4.0/22"]  # Public subnets
  private_subnets = ["192.168.8.0/22", "192.168.12.0/22"]  # Private subnets
}

# Create an Egress-Only Internet Gateway for IPv6
resource "aws_egress_only_internet_gateway" "ocean-aws-for-all-engress-only" {
  vpc_id = module.vpc.vpc_id

  tags = {
    Name = "ocean-aws-egress-only-gateway"
  }
}

# Public Subnet Configuration with IPv6
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = module.vpc.vpc_id
  cidr_block        = element(module.vpc.public_subnets, count.index)
  availability_zone = element(module.vpc.azs, count.index)

  map_public_ip_on_launch = true

  # Automatically assign an IPv6 address on creation
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "ocean-aws-for-all-public-subnet-${count.index + 1}"
  }
}

# Private Subnet Configuration with IPv6
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = module.vpc.vpc_id
  cidr_block        = element(module.vpc.private_subnets, count.index)
  availability_zone = element(module.vpc.azs, count.index)

  # Automatically assign an IPv6 address on creation
  assign_ipv6_address_on_creation = true

  tags = {
    Name = "ocean-aws-for-all-private-subnet-${count.index + 1}"
  }
}