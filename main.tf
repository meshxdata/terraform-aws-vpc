locals {
  available_azs = data.aws_availability_zones.available.names

  # Use the first N AZs when azs is a number, the given list when it is a list, otherwise all available AZs.
  azs = (
    can(tonumber(var.azs))
    ? slice(local.available_azs, 0, tonumber(var.azs))
    : (var.azs != null ? tolist(var.azs) : local.available_azs)
  )

  is_auto_mode = var.subnet_configuration.mode == "auto"

  # Auto mode carves each tier out of vpc_cidr in order: public, private, database.
  public_subnets = local.is_auto_mode && contains(var.subnet_types, "public") ? [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_configuration.subnet_size - tonumber(split("/", var.vpc_cidr)[1]), i)
  ] : try(var.subnet_configuration.public_subnets.cidrs, [])

  private_subnets = local.is_auto_mode && contains(var.subnet_types, "private") ? [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_configuration.subnet_size - tonumber(split("/", var.vpc_cidr)[1]), i + length(local.azs))
  ] : try(var.subnet_configuration.private_subnets.cidrs, [])

  database_subnets = local.is_auto_mode && contains(var.subnet_types, "database") ? [
    for i, az in local.azs : cidrsubnet(var.vpc_cidr, var.subnet_configuration.subnet_size - tonumber(split("/", var.vpc_cidr)[1]), i + 2 * length(local.azs))
  ] : try(var.subnet_configuration.database_subnets.cidrs, [])
}

data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:The default is intentionally all available AZs. Callers that need a fixed set pass azs as a number or an explicit list.
  state = "available"

  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

module "vpc" {
  #checkov:skip=CKV_TF_1:Registry modules are pinned by version constraint, not commit hash.
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = local.azs

  public_subnets   = local.public_subnets
  private_subnets  = local.private_subnets
  database_subnets = local.database_subnets

  public_subnet_suffix   = try(var.subnet_configuration.public_subnets.name_prefix, "public")
  private_subnet_suffix  = try(var.subnet_configuration.private_subnets.name_prefix, "private")
  database_subnet_suffix = try(var.subnet_configuration.database_subnets.name_prefix, "db")

  create_database_subnet_group = length(local.database_subnets) > 0

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  enable_nat_gateway     = try(var.nat_gateway_config.enable, true) && length(local.private_subnets) > 0
  single_nat_gateway     = try(var.nat_gateway_config.single_nat_gateway, false)
  one_nat_gateway_per_az = try(var.nat_gateway_config.one_nat_gateway_per_az, true)

  enable_vpn_gateway = var.enable_vpn_gateway

  public_subnet_tags   = try(var.subnet_configuration.public_subnets.tags, {})
  private_subnet_tags  = try(var.subnet_configuration.private_subnets.tags, {})
  database_subnet_tags = try(var.subnet_configuration.database_subnets.tags, {})

  enable_flow_log                                 = var.enable_flow_log
  create_flow_log_cloudwatch_log_group            = var.enable_flow_log
  create_flow_log_cloudwatch_iam_role             = var.enable_flow_log
  flow_log_cloudwatch_log_group_retention_in_days = var.flow_log_retention_days
  flow_log_traffic_type                           = "ALL"

  tags = var.tags
}

# Security group for interface endpoints: HTTPS from inside the VPC only.
resource "aws_security_group" "vpc_endpoints" {
  #checkov:skip=CKV2_AWS_5:The group is attached to the interface endpoints inside the vpc-endpoints sub-module, which this check cannot follow.
  count = var.enable_vpc_endpoints ? 1 : 0

  name_prefix = "${var.vpc_name}-vpce-"
  description = "HTTPS from inside the VPC to interface endpoints"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  ingress {
    description = "HTTPS from the VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

module "vpc_endpoints" {
  #checkov:skip=CKV_TF_1:Registry modules are pinned by version constraint, not commit hash.
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  count = var.enable_vpc_endpoints ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoints[0].id]

  endpoints = merge(
    {
      s3 = {
        service         = "s3"
        service_type    = "Gateway"
        route_table_ids = concat(module.vpc.private_route_table_ids, module.vpc.database_route_table_ids)
      }
    },
    {
      for svc in var.interface_endpoints : svc => {
        service             = svc
        private_dns_enabled = true
        subnet_ids          = module.vpc.private_subnets
      }
    }
  )

  tags = var.tags
}
