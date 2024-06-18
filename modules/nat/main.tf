#......................................nat......................................

#eip
resource "aws_eip" "eips" {
    count = length(var.count)
    domain = "vpc"
    tags = {
      Name = "eip${count.index }"
    }

}

#nat gw 
resource "aws_nat_gateway" "nat-gtws" {
  count = length(var.count)
  allocation_id = aws_eip.eips[count.index].id
  subnet_id = var.public_subnets_ids[0]
  tags = {
    Name = "nat${count.index}"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


#create route table for private subnets(allow them to reach internet)
resource "aws_route_table" "private-rt" {
    count = length(var.count)
    vpc_id = var.vpc_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.nat-gtws[count.index].id
    }
    tags = {
    Name = "Private-rt${count.index}"
  }
  
}

#rt assosiation1
resource "aws_route_table_association" "private-rt1" {
  subnet_id = var.private_subnets_ids[0]
  route_table_id = aws_route_table.private-rt[0].id
}

#rt assosiation2
resource "aws_route_table_association" "private-rt2" {
  subnet_id = var.private_subnets_ids[1]
  route_table_id = aws_route_table.private-rt[1].id
}