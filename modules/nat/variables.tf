variable "count" {
  description = "number of public subnets(2), used to create 2-eips and 2-nat"
}

variable "public_subnets_ids" {
    description = "list of public_subnets_ids "
    type = list(string)
  
}

variable "private_subnets_ids" {
    description = "list of private_subnets_ids "
    type = list(string)
  
}

variable "vpc_id" {}

