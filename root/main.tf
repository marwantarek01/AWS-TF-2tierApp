module "vpc" {
    source = "../modules/vpc"
    vpc_cidr         = var.vpc_cidr
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs = var.public_subnet_cidrs
    
}

module "nat" {
    source = "../modules/nat"
    public_subnets_ids = module.vpc.public_subnets_ids
    private_subnets_ids = module.vpc.private_subnets_ids
    vpc_id = module.vpc.vpc_id
    count = module.vpc.public_subent_count
  
}

module "sg" {
    source = "../modules/sg"
    vpc_id = module.vpc.vpc_id
  
}

module "key" {
    source = "../modules/key"
  
}

module "alb" {
    source = "../modules/alb"
    vpc_id = module.vpc.vpc_id
    alb_sg_id = module.sg.alb_sg_id
    public_subnets_ids = module.vpc.public_subnets_ids
  
}

#module "autoscaling"
module "as" {
    source = "../modules/as"
    ami = var.ami
    instance_type = var.instance_type
    max_size = var.max_size
    min_size = var.min_size
    desired_cap = var.desired_cap
    client_sg_id = module.sg.client_sg_id
    key_name = module.key.key_name
    private_subnets_ids = module.vpc.private_subnets_ids
    alb_tg_arn = module.alb.alb_tg_arn
  
}

module "rds_db" {
    source = "../modules/rds"
    private_subnets_ids = module.vpc.private_subnets_ids
    db_name = var.db_name
    db_password = var.db_password
    db_username = var.db_username
    db_sg_id = module.sg.db_sg_id

  
}

module "cloudfront" {
    source = "../modules/cloudfront"
    alb_dns_name = module.alb.alb_dns_name
    alb_id = module.alb.alb_id
  
}

module "route53" {
    source = "../modules/route53"
    cloudfront_zoneID = module.cloudfront.cloudfront_zoneID
    cloudfront_domain_name = module.cloudfront.cloudfront_domain_name
  
}


