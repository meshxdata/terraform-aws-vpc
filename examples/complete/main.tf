module "vpc" {
  source = "../../"

  vpc_name = "example"
  vpc_cidr = "10.10.0.0/16"
  azs      = 3

  subnet_types = ["public", "private", "database"]

  subnet_configuration = {
    subnet_size = 20
    public_subnets = {
      cidrs = []
      tags  = { "kubernetes.io/role/elb" = "1" }
    }
    private_subnets = {
      cidrs = []
      tags  = { "kubernetes.io/role/internal-elb" = "1" }
    }
  }

  nat_gateway_config = {
    one_nat_gateway_per_az = true
  }

  enable_flow_log         = true
  flow_log_retention_days = 90

  enable_vpc_endpoints = true

  tags = {
    Environment = "dev"
  }
}
