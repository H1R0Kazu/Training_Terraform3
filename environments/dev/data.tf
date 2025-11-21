# Existing Udemy VPC
data "aws_vpc" "udemy" {
  filter {
    name   = "tag:Name"
    values = ["udemy"]
  }
}
