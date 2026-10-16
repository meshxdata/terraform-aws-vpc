variable "vpc_name" {
  type        = string
  description = "Name of the VPC. Also used as the prefix for the endpoint security group."

  validation {
    condition     = length(var.vpc_name) > 0 && length(var.vpc_name) <= 200
    error_message = "vpc_name must be between 1 and 200 characters."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "IPv4 CIDR block for the VPC."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 28
    error_message = "vpc_cidr must be a valid IPv4 CIDR between /16 and /28."
  }
}

variable "azs" {
  type        = any
  description = "Number of availability zones to use (for example 3), or an explicit list of AZ names. Defaults to all available AZs in the region."
  default     = 2

  validation {
    condition     = var.azs == null || (can(tonumber(var.azs)) ? (tonumber(var.azs) >= 1 && tonumber(var.azs) <= 6) : (can(tolist(var.azs)) && length(tolist(var.azs)) >= 1 && length(tolist(var.azs)) <= 6))
    error_message = "azs must be a number from 1 to 6, or a list of 1 to 6 AZ names."
  }
}

variable "subnet_configuration" {
  type = object({
    mode        = optional(string, "auto")
    subnet_size = optional(number, 20)

    public_subnets = optional(object({
      cidrs       = list(string)
      name_prefix = optional(string, "public")
      tags        = optional(map(string), {})
    }))

    private_subnets = optional(object({
      cidrs       = list(string)
      name_prefix = optional(string, "private")
      tags        = optional(map(string), {})
    }))

    database_subnets = optional(object({
      cidrs       = list(string)
      name_prefix = optional(string, "db")
      tags        = optional(map(string), {})
    }))
  })
  description = "Subnet layout. mode \"auto\" carves subnets out of vpc_cidr with subnet_size as the mask; mode \"manual\" uses the explicit cidrs per tier. Per-tier tags are applied to that tier's subnets, for example Kubernetes ELB tags."
  default     = {}

  validation {
    condition     = contains(["auto", "manual"], var.subnet_configuration.mode)
    error_message = "subnet_configuration.mode must be \"auto\" or \"manual\"."
  }

  validation {
    condition     = var.subnet_configuration.subnet_size >= 16 && var.subnet_configuration.subnet_size <= 28
    error_message = "subnet_configuration.subnet_size must be between 16 and 28."
  }
}

variable "subnet_types" {
  type        = list(string)
  description = "Subnet tiers to create in auto mode. Any of: public, private, database."
  default     = ["public", "private", "database"]

  validation {
    condition     = alltrue([for t in var.subnet_types : contains(["public", "private", "database"], t)])
    error_message = "subnet_types must contain only: public, private, database."
  }
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC."
  default     = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support in the VPC."
  default     = true
}

variable "nat_gateway_config" {
  type = object({
    enable                 = optional(bool, true)
    single_nat_gateway     = optional(bool, false)
    one_nat_gateway_per_az = optional(bool, true)
  })
  description = "NAT gateway settings. Defaults to one NAT gateway per AZ, which is the highly available choice. single_nat_gateway trades availability for lower cost."
  default     = {}

  validation {
    condition     = !(try(var.nat_gateway_config.single_nat_gateway, false) && try(var.nat_gateway_config.one_nat_gateway_per_az, true))
    error_message = "single_nat_gateway and one_nat_gateway_per_az cannot both be true."
  }
}

variable "enable_vpn_gateway" {
  type        = bool
  description = "Create a VPN gateway attached to the VPC."
  default     = false
}

variable "enable_flow_log" {
  type        = bool
  description = "Send VPC flow logs to CloudWatch Logs."
  default     = false
}

variable "flow_log_retention_days" {
  type        = number
  description = "Retention in days for the flow log CloudWatch log group. Must be a value CloudWatch Logs accepts."
  default     = 90

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "flow_log_retention_days must be a value CloudWatch Logs accepts, for example 30, 90, 365."
  }
}

variable "enable_vpc_endpoints" {
  type        = bool
  description = "Create an S3 gateway endpoint and interface endpoints for the services in interface_endpoints, so traffic to AWS services stays private."
  default     = false
}

variable "interface_endpoints" {
  type        = list(string)
  description = "Interface endpoint services to create when enable_vpc_endpoints is true."
  default     = ["ecr.api", "ecr.dkr", "sts", "secretsmanager", "logs", "ssm", "ssmmessages", "ec2messages"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource the module creates."
  default     = {}
}
