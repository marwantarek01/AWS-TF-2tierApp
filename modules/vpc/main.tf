#......................................vpc......................................
# create vpc
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "my-vpc"
  }
} 

#create igw
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "my-igw"
  }
}
#azs in the region
data "aws_availability_zones" "available_zones" {

}

#create private subnets 

resource "aws_subnet" "private_subnets" {
   count = length(var.private_subnet_cidrs)
   vpc_id = aws_vpc.vpc.id
   cidr_block = var.private_subnet_cidrs[count.index]
   availability_zone = data.aws_availability_zones.available_zones.names[count.index % 2]
   tags = {
     Name = "private-subnet${count.index +1}-az${count.index % 2}"
   }
}


#create public subnets 
resource "aws_subnet" "public_subnets" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = data.aws_availability_zones.available_zones.names[count.index]
    tags = {
        Name = "public_subnet${count.index +1} az${count.index}"
    }
}

#create route table for public subnets(allow them to reach internet)
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
    tags = {
    Name = "Public-rt"
  }
  
}

#rt assosiation1
resource "aws_route_table_association" "public-rt1" {
  subnet_id = aws_subnet.public_subnets[0].id
  route_table_id = aws_route_table.public_rt.id
}

#rt assosiation2
resource "aws_route_table_association" "public-rt2" {
  subnet_id = aws_subnet.public_subnets[1].id
  route_table_id = aws_route_table.public_rt.id
}