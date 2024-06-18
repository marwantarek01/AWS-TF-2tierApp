variable "alb_sg_id" {}

variable "vpc_id" {}

variable "public_subnets_ids" {
    description = "list of public_subnets_ids "
    type = list(string)
  
}
