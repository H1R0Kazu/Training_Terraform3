locals {
  # Prefix List Entries - 30 entries to test capacity limit with aws_security_group_rule
  prefix_list_entries = [
    for i in range(1, 31) : {
      cidr        = "10.0.${i}.0/24"
      description = "Test Entry ${i}"
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
