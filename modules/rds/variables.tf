variable "private_subnets_ids" {
    description = "list of private_subnets_ids "
    type = list(string)
  
}
variable "count" {
  description = "count of read replicas"
}

variable "db_username" {}

variable "db_password" {}

variable "db_name" {}

variable "db_sg_id" {}

