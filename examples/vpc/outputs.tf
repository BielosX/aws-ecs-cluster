output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "public-subnet-ids" {
  value = aws_subnet.public-subnets[*].id
}

output "cluster-subnet-ids" {
  value = aws_subnet.cluster-subnets[*].id
}

output "lb-subnet-ids" {
  value = aws_subnet.lb-subnets[*].id
}

output "container-subnet-ids" {
  value = aws_subnet.cluster-subnets[*].id
}