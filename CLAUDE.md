# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform training/testing repository for learning AWS infrastructure provisioning. The project demonstrates creating AWS Managed Prefix Lists and Security Groups using AWS Provider 5.0+ resource types.

**Primary Goal**: Demonstrate the use of new security group rule resource types (`aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule`) with Prefix Lists.

## Common Commands

All Terraform commands should be run from within an environment directory (e.g., `environments/dev`):

```bash
cd environments/dev

# Initialize Terraform (required after cloning or adding new providers)
terraform init

# View planned changes before applying
terraform plan

# Apply infrastructure changes
terraform apply

# Destroy all managed resources
terraform destroy

# Format Terraform files
terraform fmt -recursive

# Validate configuration syntax
terraform validate
```

## Architecture

### Directory Structure

- `environments/`: Environment-specific configurations (dev, staging, prod)
  - Each environment contains a complete Terraform configuration
  - Currently only `dev` environment is implemented
- `modules/`: Reusable Terraform modules (currently empty, for future use)

### File Organization Pattern

Each environment follows this file organization:

- `terraform.tf`: Terraform and provider version constraints
- `provider.tf`: AWS provider configuration with default tags
- `variables.tf`: Input variable definitions
- `data.tf`: Data sources (e.g., existing VPC lookup)
- `locals.tf`: Local values for prefix list entries and security group ingress rules
- `main.tf`: Managed Prefix List resource definition
- `security_group.tf`: Security Group and ingress/egress rule resources
- `outputs.tf`: Output values

### Key Design Patterns

**Dynamic Configuration via Locals**: The project uses `locals.tf` to define data structures that drive dynamic resource creation:

- `prefix_list_entries`: List of CIDR blocks for the Managed Prefix List (5 entries)
- `security_group_ingress_rules`: List of ingress rules (ports 443, 80, 22) that reference the prefix list

**Separation of Security Group Rules**: Security group rules are defined as separate resources using the new AWS Provider 5.0+ resource types:

- `aws_vpc_security_group_ingress_rule`: For ingress rules
- `aws_vpc_security_group_egress_rule`: For egress rules

This approach avoids mixing inline rules with standalone rule resources, which can cause Terraform state conflicts.

**Data Source Dependencies**: The security group depends on an existing VPC named "udemy" (queried via `data.aws_vpc.udemy`).

### Resource Relationships

```text
data.aws_vpc.udemy (existing VPC)
    ↓
aws_ec2_managed_prefix_list.test_miyata (Prefix List with 5 entries from locals)
    ↓
aws_security_group.test_with_prefix_list (Security Group in VPC)
    ↓
aws_vpc_security_group_ingress_rule.from_prefix_list (3 dynamic ingress rules using for_each)
aws_vpc_security_group_egress_rule.allow_all (Single egress rule - allow all)
```

## Requirements

- Terraform >= 1.12.2
- AWS Provider ~> 5.0 (required for new security group rule resources)
- AWS CLI configured with appropriate credentials
- An existing VPC tagged with `Name = "udemy"` in the target AWS region (ap-northeast-1)

## Default Configuration

- Region: `ap-northeast-1` (Tokyo)
- Project: `terraform-training`
- Environment: `dev`
- Default tags applied to all resources: Environment, ManagedBy, Project

## Current Implementation Details

### Prefix List Configuration

- **Name**: `test-miyata-prefix-list`
- **Resource ID**: `pl-026264adbef1f2da0`
- **Address Family**: IPv4
- **Max Entries**: 10
- **Current Entries**: 5 (manually defined in locals)
- **CIDR Ranges**:
  - `10.0.1.0/24` - Office A
  - `10.0.2.0/24` - Office B
  - `192.168.1.0/24` - VPN Connection
  - `172.16.0.0/24` - Remote Work
  - `203.0.113.0/24` - Partner Company (Test IP)

### Security Group Configuration

- **Name**: `test-sg-with-prefix-list`
- **Resource ID**: `sg-0b04a69009c80dd71`
- **VPC**: Existing "udemy" VPC (`vpc-026cf542cccbb039e`)
- **Ingress Rules**: 3 rules (HTTPS/443, HTTP/80, SSH/22) referencing the prefix list
- **Egress Rules**: 1 rule (allow all outbound traffic)
- **Resource Types**: Uses AWS Provider 5.0+ new resource types
  - `aws_vpc_security_group_ingress_rule`
  - `aws_vpc_security_group_egress_rule`

### Current Security Group Rule IDs

Created with new resource types (as of 2025-11-21):

- **Egress Rule**: `sgr-0d3e635e3980a0033` - Allow all outbound traffic
- **Ingress Rules**:
  - `sgr-0ef793c82f0c0df96` - HTTPS (443/tcp) from prefix list
  - `sgr-011fb2caf33e7dd1b` - HTTP (80/tcp) from prefix list
  - `sgr-07a27dcf3d05111a7` - SSH (22/tcp) from prefix list

## New Resource Types (AWS Provider 5.0+)

### Key Differences from Legacy Resources

**Legacy (aws_security_group_rule):**
```hcl
resource "aws_security_group_rule" "example" {
  type              = "ingress"  # Required
  protocol          = "tcp"
  prefix_list_ids   = [...]      # Plural
  cidr_blocks       = [...]      # Plural
  ...
}
```

**New (aws_vpc_security_group_ingress_rule):**
```hcl
resource "aws_vpc_security_group_ingress_rule" "example" {
  # No 'type' field - implicitly ingress
  ip_protocol     = "tcp"        # Changed from 'protocol'
  prefix_list_id  = "..."        # Singular
  cidr_ipv4       = "..."        # Changed from 'cidr_blocks'
  ...
}
```

### Benefits of New Resource Types

- **Clearer Intent**: Separate resources for ingress and egress
- **No Type Field**: Resource name implies direction
- **Better Terraform State Management**: Avoids conflicts between inline and standalone rules
- **AWS Best Practices**: Recommended approach for AWS Provider 5.0+

## Important Notes

- **Do not mix inline rules with standalone rule resources**: If using `aws_vpc_security_group_ingress_rule` or `aws_vpc_security_group_egress_rule`, do NOT use inline `ingress {}` or `egress {}` blocks in the `aws_security_group` resource
- **Security group must exist first**: The security group resource must be created before the rule resources can reference it
- **Prefix list must exist first**: The prefix list must be created before security group rules can reference it
