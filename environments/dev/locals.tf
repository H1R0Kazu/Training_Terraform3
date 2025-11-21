locals {
  prefix_list_entries = [
    {
      cidr        = "10.0.1.0/24"
      description = "Office A"
    },
    {
      cidr        = "10.0.2.0/24"
      description = "Office B"
    },
    {
      cidr        = "192.168.1.0/24"
      description = "VPN Connection"
    },
    {
      cidr        = "172.16.0.0/24"
      description = "Remote Work"
    },
    {
      cidr        = "203.0.113.0/24"
      description = "Partner Company (Test IP)"
    }
  ]

  # Security Group Ingress Rules
  security_group_ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "Allow HTTPS from prefix list IPs"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "Allow HTTP from prefix list IPs"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH from prefix list IPs"
    }
  ]
}
