resource "aws_vpc" "vpc" {
  enable_dns_hostnames = true
  enable_dns_support = true
  cidr_block = var.cidr
  tags = {
    Name: var.name-prefix
  }
}

resource "aws_eip" "nat-gw-eip" {
  vpc = true
  tags = {
    Name: "${var.name-prefix}-nat-gw-eip"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public-subnets" {
  count = length(var.public-subnets)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.public-subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone = var.availability-zones[count.index]
  tags = {
    Name: "${var.name-prefix}-public-subnet"
  }
}

resource "aws_nat_gateway" "nat-gw" {
  subnet_id = aws_subnet.public-subnets[0].id
  allocation_id = aws_eip.nat-gw-eip.id
  tags = {
    Name: "${var.name-prefix}-nat-gw"
  }
}

resource "aws_subnet" "lb-subnets" {
  count = length(var.lb-subnets)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.lb-subnets[count.index]
  availability_zone = var.availability-zones[count.index]
  tags = {
    Name: "${var.name-prefix}-lb-subnet"
  }
}

resource "aws_subnet" "cluster-subnets" {
  count = length(var.cluster-subnets)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.cluster-subnets[count.index]
  availability_zone = var.availability-zones[count.index]
  tags = {
    Name: "${var.name-prefix}-cluster-subnet"
  }
}

resource "aws_subnet" "container-subnets" {
  count = length(var.container-subnets)
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.container-subnets[count.index]
  availability_zone = var.availability-zones[count.index]
  tags = {
    Name: "${var.name-prefix}-container-subnet"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name: "${var.name-prefix}-public-route-table"
  }
}

resource "aws_route_table_association" "public-route-table-assoc-public-subnets" {
  count = length(var.public-subnets)
  route_table_id = aws_route_table.public-route-table.id
  subnet_id = aws_subnet.public-subnets[count.index].id
}

resource "aws_route_table_association" "public-route-table-assoc-lb-subnets" {
  count = length(var.lb-subnets)
  route_table_id = aws_route_table.public-route-table.id
  subnet_id = aws_subnet.lb-subnets[count.index].id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name: "${var.name-prefix}-private-route-table"
  }
}

resource "aws_route_table_association" "private-route-table-assoc-cluster-subnets" {
  count = length(var.cluster-subnets)
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.cluster-subnets[count.index].id
}

resource "aws_route_table_association" "private-route-table-assoc-container-subnets" {
  count = length(var.container-subnets)
  route_table_id = aws_route_table.private-route-table.id
  subnet_id = aws_subnet.container-subnets[count.index].id
}
