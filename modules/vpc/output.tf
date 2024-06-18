output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "private_subnets_ids" {
    value = aws_subnet.private_subnets[*].id
}


output "public_subnets_ids" {
    value = aws_subnet.public_subnets[*].id
}

output "public_subent_count" {
  value = length(aws_subnet.public_subnets)
}