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
}
