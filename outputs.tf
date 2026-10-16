output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}

output "azs" {
  description = "The availability zones used."
  value       = local.azs
}

output "public_subnets" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnets
}

output "database_subnets" {
  description = "IDs of the database subnets."
  value       = module.vpc.database_subnets
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group, or null when there are no database subnets."
  value       = try(module.vpc.database_subnet_group_name, null)
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = module.vpc.natgw_ids
}

output "igw_id" {
  description = "ID of the internet gateway."
  value       = module.vpc.igw_id
}

output "local_azs" {
  description = "Deprecated alias of azs, kept for existing callers."
  value       = local.azs
}

output "local_public_subnets" {
  description = "Subnet CIDRs computed for the public tier, kept for existing callers."
  value       = local.public_subnets
}

output "local_private_subnets" {
  description = "Subnet CIDRs computed for the private tier, kept for existing callers."
  value       = local.private_subnets
}

output "local_database_subnets" {
  description = "Subnet CIDRs computed for the database tier, kept for existing callers."
  value       = local.database_subnets
}
