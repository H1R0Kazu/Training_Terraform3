# Security Group using Prefix List
resource "aws_security_group" "test_with_prefix_list" {
  name        = "test-sg-with-prefix-list"
  description = "Security group using managed prefix list for testing"
  vpc_id      = data.aws_vpc.udemy.id

  tags = {
    Name = "test-sg-with-prefix-list"
  }
}

# Ingress rules from Prefix List (using aws_security_group_rule)
resource "aws_security_group_rule" "ingress_from_prefix_list" {
  for_each = { for idx, rule in local.security_group_ingress_rules : idx => rule }

  type              = "ingress"
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  prefix_list_ids   = [aws_ec2_managed_prefix_list.test_miyata.id]
  security_group_id = aws_security_group.test_with_prefix_list.id
  description       = each.value.description
}

# Egress rule: Allow all outbound traffic (using aws_security_group_rule)
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.test_with_prefix_list.id
  description       = "Allow all outbound traffic"
}
