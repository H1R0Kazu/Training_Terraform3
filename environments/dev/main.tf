# Managed Prefix List
resource "aws_ec2_managed_prefix_list" "test_miyata" {
  name           = "test-miyata-prefix-list"
  address_family = "IPv4"
  max_entries    = 50

  dynamic "entry" {
    for_each = local.prefix_list_entries
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }

  tags = {
    Name = "test-miyata-prefix-list"
  }
}
