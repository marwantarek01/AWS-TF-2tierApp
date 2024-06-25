
resource "aws_db_subnet_group" "db-subnet" {
  name       = "rds_db"
  subnet_ids = [var.private_subnets_ids[2], var.private_subnets_ids[3]] #  private subnet IDs
}

resource "aws_db_instance" "db" {
  identifier              = "mysql-instance"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t2.micro"
  allocated_storage       = 20
  username                = var.db_username
  password                = var.db_password
  db_name                 = var.db_name
  multi_az                = true
  storage_type            = "gp2"
  storage_encrypted       = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = 0

  vpc_security_group_ids = [var.db_sg_id] # security group ID

  db_subnet_group_name = aws_db_subnet_group.db-subnet.name

  tags = {
    Name = "mysql-instance"
  }
}


resource "aws_db_instance" "read_replica" {
  count = var.count
  instance_class               = "db.t2.micro" 

  # Optional: Customize as needed
  publicly_accessible          = false
  storage_type                 = "gp2"
  db_subnet_group_name         = aws_db_subnet_group.db-subnet.name
  vpc_security_group_ids       = [var.db_sg_id] # security group ID
  replicate_source_db = aws_db_instance.db.identifier
  tags = {
    Name = "Read Replica"
  }
}

