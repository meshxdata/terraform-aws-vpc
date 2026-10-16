# terraform-aws-vpc

Creates a VPC with public, private, and database subnets across availability zones, NAT gateways, optional VPC flow logs, and optional VPC endpoints. The networking is built on [terraform-aws-modules/vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc) (~> 5.0).

## Defaults

- Subnets are carved from `vpc_cidr` automatically (`subnet_configuration.mode = "auto"`), or set explicitly with `"manual"`.
- One NAT gateway per AZ (`one_nat_gateway_per_az = true`). Set `single_nat_gateway = true` to trade availability for lower cost.
- Flow logs are off by default. Turn them on with `enable_flow_log`. Retention defaults to 90 days.
- VPC endpoints are off by default. When on, an S3 gateway endpoint and interface endpoints for `interface_endpoints` are created.

## Usage

```hcl
module "vpc" {
  source  = "meshxdata/vpc/aws"
  version = "~> 1.0"

  vpc_name = "platform"
  vpc_cidr = "10.10.0.0/16"
  azs      = 3

  subnet_configuration = {
    subnet_size = 20
    private_subnets = {
      cidrs = []
      tags  = { "kubernetes.io/role/internal-elb" = "1" }
    }
  }

  enable_flow_log         = true
  flow_log_retention_days = 90

  enable_vpc_endpoints = true

  tags = {
    Environment = "dev"
  }
}
```

See [examples/complete](examples/complete) for a full example.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_name | Name of the VPC. Also the prefix for the endpoint security group. | `string` | n/a | yes |
| vpc_cidr | IPv4 CIDR block for the VPC, between /16 and /28. | `string` | `"10.0.0.0/16"` | no |
| azs | Number of AZs (1 to 6), or an explicit list of AZ names. | `any` | `2` | no |
| subnet_configuration | Subnet layout: `mode` (`auto` or `manual`), `subnet_size`, and per-tier `public_subnets`, `private_subnets`, `database_subnets` with `cidrs`, `name_prefix`, and `tags`. | `object` | `{}` | no |
| subnet_types | Tiers to create in auto mode: `public`, `private`, `database`. | `list(string)` | all three | no |
| enable_dns_hostnames | Enable DNS hostnames. | `bool` | `true` | no |
| enable_dns_support | Enable DNS support. | `bool` | `true` | no |
| nat_gateway_config | `enable`, `single_nat_gateway`, `one_nat_gateway_per_az`. | `object` | per-AZ NAT | no |
| enable_vpn_gateway | Create a VPN gateway. | `bool` | `false` | no |
| enable_flow_log | Send VPC flow logs to CloudWatch Logs. | `bool` | `false` | no |
| flow_log_retention_days | Flow log retention in days. Must be a value CloudWatch Logs accepts. | `number` | `90` | no |
| enable_vpc_endpoints | Create the S3 gateway endpoint and the interface endpoints in `interface_endpoints`. | `bool` | `false` | no |
| interface_endpoints | Interface endpoint services to create when `enable_vpc_endpoints` is true. | `list(string)` | ECR, STS, Secrets Manager, CloudWatch Logs, SSM | no |
| tags | Tags applied to every resource the module creates. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The VPC ID. |
| vpc_cidr_block | The VPC CIDR block. |
| azs | The AZs used. |
| public_subnets | Public subnet IDs. |
| private_subnets | Private subnet IDs. |
| database_subnets | Database subnet IDs. |
| database_subnet_group_name | Database subnet group name, or null when there are no database subnets. |
| nat_gateway_ids | NAT gateway IDs. |
| igw_id | Internet gateway ID. |

## Checks

CI runs `terraform fmt`, `terraform validate`, Checkov, and Trivy on every push. Checkov checks that cannot apply to a reusable module are skipped in `main.tf` with written reasons.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | ~> 5.0 |
