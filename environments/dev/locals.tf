locals {
  # Prefix List Entries - 30 entries to test Security Group rule limit (60)
  # Total rules will be 30 entries × 3 rules = 90 rules (exceeds AWS limit of 60)
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
