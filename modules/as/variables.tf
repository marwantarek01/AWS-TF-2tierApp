variable "ami" {}
variable "instance_type" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_cap" {}
variable "asg_health_check_type" { 
    default = "ELB"
}


variable "client_sg_id" {}
variable "key_name" {}
variable "private_subnets_ids" {
    description = "list of private_subnets_ids "
    type = list(string)
  
}

variable "alb_tg_arn" {}
