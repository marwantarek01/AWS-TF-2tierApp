variable "vpc_cidr" {}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
 # default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


variable "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  #default     = ["10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

###############################################################
#asg
variable "ami" {
  default = "skx8987"
}

variable "instance-type" {
  default = "t2.micro"  
}

variable "max_size" {
    default = 6
}

variable "min_size" {
    default = 2
}

variable "desired_cap" {
    default = 3
}

variable "asg_health_check_type" {
    default = "ELB"
}

