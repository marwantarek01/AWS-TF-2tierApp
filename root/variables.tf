variable "region" {}
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

#db vars

variable "db_username" {}

variable "db_password" {}

variable "db_name" {}


#as vars
variable "ami" {}
variable "instance_type" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_cap" {}

variable "appname" {
  
}