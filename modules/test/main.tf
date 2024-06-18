

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

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#......................................nat......................................

#eip
resource "aws_eip" "eips" {
    count = length(aws_subnet.public_subnets)
    domain = "vpc"
    tags = {
      Name = "eip${count.index }"
    }

}

#nat gw 
resource "aws_nat_gateway" "nat-gtws" {
  count = length(aws_subnet.public_subnets)
  allocation_id = aws_eip.eips[count.index].id
  subnet_id = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "nat${count.index}"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}


#create route table for private subnets(allow them to reach internet)
resource "aws_route_table" "private-rt" {
    count = length(aws_subnet.public_subnets)
    vpc_id = aws_vpc.vpc.id
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
  subnet_id = aws_subnet.private_subnets[0].id
  route_table_id = aws_route_table.private-rt[0].id
}

#rt assosiation2
resource "aws_route_table_association" "private-rt2" {
  subnet_id = aws_subnet.private_subnets[1].id
  route_table_id = aws_route_table.private-rt[1].id
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#......................................security groups....................................
#sg for alb
resource "aws_security_group" "alb_sg" {
  name = "alb_sg"
  description = "enable http/https access on port 80/443"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "alb_sg"
  }
  
}

# create security group for the Client
resource "aws_security_group" "client_sg" {
  name = "client_sg"
  description = " enable http/https access on port 80 for elb sg"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "client_sg"
  }
  
}

# create security group for the Database
resource "aws_security_group" "db_sg" {
  name = "db_sg"
  description = "sg for db"
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port = 3306 
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.client_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "db_sg"
  }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#......................................ec2 key pair....................................

resource "aws_key_pair" "client_key" {
  key_name = "client key"
  public_key = "YOUR PUBLIC KEY PATH"
  
}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#..................................application load balancer..................................
#create alb
resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]
  tags = {
    Name = "alb"
  }
}

#create application load balancer target group
resource "aws_lb_target_group" "alb_tg" {
  name     = "alb_tg"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
  health_check {
    enabled             = true
    interval            = 300
    path                = "/"
    timeout             = 60
    matcher             = 200
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
   lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "alb-tg"
  }

}

# create a listener on port 80 with fwd action
resource "aws_lb_listener" "alb_listner" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#..................................asg..................................

resource "aws_launch_template" "lunch-template" {
  name = "lunch-template"
  image_id = var.ami
  instance_type = var.instance-type
  security_group_names = aws_security_group.client_sg
  key_name = aws_key_pair.client_key.key_name
}



#---------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#..................................cloudfront..................................

resource "aws_cloudfront_distribution" "my_distribution" {
  enabled = true
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id = aws_lb.alb.id
     custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [ "TLSv1.2" ]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD" ]
    cached_methods         = ["GET", "HEAD" ]
    target_origin_id       = aws_lb.alb.id
    viewer_protocol_policy = "redirect-to-https"  
  }
   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  
}


#-------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

#..................................r53.........................................
resource "aws_route53_zone" "my-zone" {
  name = "myapp.com"
  
}

resource "aws_route53_record" "cloudfront" {
  zone_id = aws_route53_zone.my-zone.id
  name = "cloudfront record"
  type = "A"
  alias {
    zone_id = aws_cloudfront_distribution.my_distribution.hosted_zone_id
    name = aws_cloudfront_distribution.my_distribution.domain_name
    evaluate_target_health = false
  }
  
}