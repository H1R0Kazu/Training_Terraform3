output "aws_region" {
  description = "AWS region being used"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "prefix_list_id" {
  description = "ID of the managed prefix list"
  value       = aws_ec2_managed_prefix_list.test_miyata.id
}

output "prefix_list_arn" {
  description = "ARN of the managed prefix list"
  value       = aws_ec2_managed_prefix_list.test_miyata.arn
}

output "security_group_id" {
  description = "ID of the security group using prefix list"
  value       = aws_security_group.test_with_prefix_list.id
}

output "vpc_id" {
  description = "ID of the Udemy VPC"
  value       = data.aws_vpc.udemy.id
}
