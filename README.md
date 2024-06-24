# AWS 2-Tier WebbApp Deployment with Terraform 

This project aims to develop scalable and secure AWS resources to deploy a two-tier application, utilizing Terraform for automated provisioning. The approach adheres to best practices in Terraform coding and architectural design principles.
## Table of Contents  

1. [ Architecture](#architecture)
2. [Features and best practices](#features-and-best-practices)
3. [Aws resources](#aws-resources)
4. [Modules](#modules)
    - [VPC](#vpc)
    - [NAT](#nat)
    - [SG](#sg)
    - [key](#key)
    - [ALB](#alb)
    - [AS](#as)
    - [RDS](#rds)
    - [Cloudfront](#cloudfront)
    - [Route53](#route-53)
    
5. [Create terraform.tfvars file](#create-terraformtfvars-file)


## Architecture

![Architecture](https://github.com/marwantarek01/assets/blob/main/aws%20proj%20(1).png)

- The architecture leverages Amazon Route 53 for DNS management, directing traffic to Amazon CloudFront.  
- CloudFront forwards requests to an Application Load Balancer (ALB), which distributes traffic across EC2 instances housed in private subnets.
- Auto Scaling is configured for the EC2 instances to dynamically adjust capacity based on demand.
-  NAT Gateways are employed to enable outbound internet access for the private instances without exposing them directly to the internet
- application data is managed by Amazon RDS in a primary-standby setup for high availability and automatic failover. 
 



## Features and best practices

- Grouping related resources into modules to simplify code organization and Management.
- Defining variables in the ```terraform.tfvars``` file.
- Outputting  values that might be required by other configurations or modules.
- Utilizing 2 availability zones to ensure high availability and fault tolerance.
- Employing separate security groups for different application tiers and resources.
- Creating a standby RDS instance for high availability and disaster recovery.
- Using CloudFront to cache and deliver content with low latency and high transfer speeds globally.   
- internet facing alb to ensure secure and efficient handling of application workloads.


## Aws resources 
  - aws_vpc
  - aws_internet_gateway
  - aws_subnet
  - aws_route_table
  - aws_route_table_association
  - aws_lb
  - aws_lb_target_group
  - aws_lb_listener
  - aws_launch_template
  - aws_autoscaling_group
  - aws_cloudwatch_metric_alarm
  - aws_autoscaling_policy
  - aws_key_pair
  - aws_eip
  - aws_nat_gateway
  - aws_db_subnet_group
  - aws_db_instance
  - aws_security_group
  - aws_cloudfront_distribution
  - aws_route53_zone
  - aws_route53_record


# Modules
## vpc 
- This Terraform module generates the specified number of public and private subnets based on the provided values for ```private_subnet_cidrs``` and ```public_subnet_cidrs``` specified in the ```terraform.tfvars``` file. It also includes the creation of an internet gateway and route tables for these subnets

- In this project I created 2 public subnets, 4 private subnets,  internet gateway and route tables.

- Inputs 

| Variable              | Description                                      |
|-----------------------|--------------------------------------------------|
| vpc_cidr              | The CIDR block for the VPC.                      |
| private_subnet_cidrs  | List of CIDR blocks for private subnets.         |
| public_subnet_cidrs   | List of CIDR blocks for public subnets           |                   

- Outputs 

| Variable              | Description                                      |
|-----------------------|--------------------------------------------------|
| vpc_id                | The VPC ID.                      |
| private_subnets_ids   | List of IDs for private subnets.                 |
| public_subnets_ids    | List of IDs for public subnets                   |                   
| public_subnet_count   | number of public subnets created                 |

- Usage  
    ```
    module "vpc" {
        source = "../modules/vpc"
        vpc_cidr             = var.vpc_cidr
        private_subnet_cidrs = var.private_subnet_cidrs
        public_subnet_cidrs  = var.public_subnet_cidrs   
    }
    ```
 ## nat
 - This module creates NAT Gateways, elastic IPs and route tables to enable outbound internet access for the private instances without exposing them directly to the internet.    
 - The number of NAT Gateways and  elastic IPs are equal to the number of public subnets 

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| vpc_id                | The VPC ID                             |
| private_subnets_ids   | List of IDs for private subnets.                        |
| public_subnets_ids    | List of IDs for public subnets.                         |                   
| count                 | number of nat gateways, route tables and eips created   |

- Usage  
    ```
    module "nat" {
        source = "../modules/nat"
        public_subnets_ids = module.vpc.public_subnets_ids
        private_subnets_ids = module.vpc.private_subnets_ids
        vpc_id = module.vpc.vpc_id
        count = module.vpc.public_subent_count
    }
    ```

## sg
 This module creates security groups for the alb , web servers and database        

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| vpc_id                | The VPC ID                             |

- Outputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| alb_sg_id             | The alb security group ID                               |
| db_sg_id              | The db security group ID                                |

- Usage  
    ```
    module "sg" {
        source = "../modules/sg"
        vpc_id = module.vpc.vpc_id
    }
    ```
## key
This module creates Key pair to enable SSH access for the EC2 instances.

- Outputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| key_name              | Key pair name for SSH access                            |

- Usage  
    ```
    module "key" {
        source = "../modules/key"
    
    }
    ```
## alb
 This module creates application loadbalancer with target groups and alb listener.    

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| vpc_id                | The VPC ID                            |
| alb_sg_id             | The alb security group ID                               |
| public_subnets_ids    | List of IDs for public subnets                             |

- Outputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| alb_dns_name          | The alb dns name                                        |
| alb_id                | The alb ID                                              |

- Usage  
    ```
    module "alb" {
        source = "../modules/alb"
        vpc_id = module.vpc.vpc_id
        alb_sg_id = module.sg.alb_sg_id
        public_subnets_ids = module.vpc.public_subnets_ids
    
    }
    ```

## as
 This module sets up a complete auto-scaling environment with an EC2 launch template, an auto-scaling group, policies, and alarms to dynamically adjust the number of instances based on CPU utilization.   

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| ami                   | The ami used to create the EC2 instance                 |
| instance_type         |  Type of the EC2 instance (e.g., t2.micro)              |
| max_size              | Maximum number of instances                             |
| min_size              | Minimum number of instances                             |
| desired_cap           | Desired number of instances                             |
| client_sg_id          | Security group IDs associated with the instances        |
| key_name              | Key pair name for SSH access                            |
|private_subnets_ids    | List of IDs for private subnets                         |
|alb_tg_arn             | ARN of the target group for load balancing              |


- Usage  
    ```
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
    ```
## rds
 This module creates Amazon RDS in a primary-standby setup.

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| db_name               | name of the database to be created in the RDS instance  |
| db_password           | database password                                       |
| private_subnets_ids   | List of IDs for private subnets                         |
| db_username           | username for the database's master user                 |
| db_sg_id              | Security group IDs associated with the rds              |
| count                 | count of read replicas                        |

- Outputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| primary_endpoint      | endpoint attribute of the primary db instance           |
| read_replica_endpoint  | endpoint attribute of the read replica db instance     |



- Usage  
    ```
    module "rds_db" {
        source = "../modules/rds"
        private_subnets_ids = module.vpc.private_subnets_ids
        db_name = var.db_name
        db_password = var.db_password
        db_username = var.db_username
        db_sg_id = module.sg.db_sg_id
        count = var.count
    }
    ```
## cloudfront
 This module creates an AWS CloudFront distribution that uses an Application Load Balancer (ALB) as its origin.

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
| alb_dns_name          |     The alb dns name                                    |
| alb_id                |    The alb ID                                           |

- Outputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
|cloudfront_zoneID      | Route 53 hosted zone ID for an AWS CloudFront distribution|
|cloudfront_domain_name | domain name of AWS CloudFront distribution  |

- Usage  
    ```
    module "cloudfront" {
        source = "../modules/cloudfront"
        alb_dns_name = module.alb.alb_dns_name
        alb_id = module.alb.alb_id
    }
    ```
## route 53
 This module creates and configures a DNS record in AWS Route 53 to point to a CloudFront distribution

- Inputs 

| Variable              | Description                                             |
|-----------------------|---------------------------------------------------------|
|cloudfront_zoneID      | Route 53 hosted zone ID for an AWS CloudFront distribution|
|cloudfront_domain_name | domain name of AWS CloudFront distribution               |
|appname                | domain name for the Route 53 hosted zone                 |

- Usage  
    ```
    module "route53" {
        source = "../modules/route53"
        cloudfront_zoneID = module.cloudfront.cloudfront_zoneID
        cloudfront_domain_name = module.cloudfront.cloudfront_domain_name  
    }
    ```


#  Create terraform.tfvars file 
```
appname = ""
region = ""
vpc_cidr = ""
private_subnet_cidrs = ""
public_subnet_cidrs = ""
db_name = ""
db_password = ""
db_username = ""
ami = ""             # The ami used to create web servers
instance_type = ""   # Type of the EC2 instance (e.g., t2.micro)
max_size =           # Maximum number of web server instances that can be scaled up
min_size =           # Minimum number of web server instances that can be scaled down
desired_cap =        # Desired number of webservers
count =              # count of read replica
```