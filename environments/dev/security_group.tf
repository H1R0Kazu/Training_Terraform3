# Security Group using Prefix List
resource "aws_security_group" "test_with_prefix_list" {
  name        = "test-sg-with-prefix-list"
  description = "Security group using managed prefix list for testing"
  vpc_id      = data.aws_vpc.udemy.id

  tags = {
    Name = "test-sg-with-prefix-list"
  }
}

# Ingress rules from Prefix List (using aws_vpc_security_group_ingress_rule)
resource "aws_vpc_security_group_ingress_rule" "from_prefix_list" {
  for_each = { for idx, rule in local.security_group_ingress_rules : idx => rule }

  security_group_id = aws_security_group.test_with_prefix_list.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  prefix_list_id    = aws_ec2_managed_prefix_list.test_miyata.id
  description       = each.value.description
}

# Egress rule: Allow all outbound traffic (using aws_vpc_security_group_egress_rule)
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.test_with_prefix_list.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}
