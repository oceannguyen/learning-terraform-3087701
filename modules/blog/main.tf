module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"  # Specified version

  name          = "ocean-aws-for-all-vpc"
  cidr          = "192.168.0.0/20"
  azs           = ["ap-southeast-1a", "ap-southeast-1b"]  # Specify your availability zones
  enable_ipv6   = true

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

resource "aws_subnet" "private" {
  count                   = length(module.vpc.private_subnets)
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = module.vpc.private_subnets[count.index]
  
  map_public_ip_on_launch = false
  availability_zone       = element(module.vpc.azs, count.index)

  ipv6_cidr_block         = cidrsubnet(module.vpc.ipv6_cidr_block, 8, count.index) # Associate IPv6 CIDR block
}

resource "aws_subnet" "public" {
  count                   = length(module.vpc.public_subnets)
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = module.vpc.public_subnets[count.index]
  
  map_public_ip_on_launch = true
  availability_zone       = element(module.vpc.azs, count.index)

  ipv6_cidr_block         = cidrsubnet(module.vpc.ipv6_cidr_block, 8, count.index) # Associate IPv6 CIDR block
}

# Check if an Egress-Only Internet Gateway already exists before creating a new one.
data "aws_egress_only_internet_gateway" "existing" {
  filter {
    name   = "vpc-id"
    values = [module.vpc.vpc_id]
  }
}

resource "aws_egress_only_internet_gateway" "egw" {
  count   = length(data.aws_egress_only_internet_gateway.existing.*.id) == 0 ? 1 : 0
  vpc_id   = module.vpc.vpc_id

  tags = {
    Name = "egress-only-internet-gateway"
  }
}