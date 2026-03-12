##################################################### Secrets Manager Secret ############################################################

resource "random_password" "db_password" {
  length           = 16
  special          = false
}

resource "aws_secretsmanager_secret" "rds_secret" {
  name = "prod/rds/db-instance-password"
  kms_key_id = var.master_user_secret_kms_key_id
  recovery_window_in_days  = 0  ### If you want to delete the secrets immediately, Default vaule is 7 days.
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.db_password.result
  })
}

##################################################### Security Group for RDS ############################################################

resource "aws_security_group" "rds_sg" {
 name        = "RDS-Security-Group-${var.env}"
 description = "Allow All Traffic"
 vpc_id      = data.aws_vpc.aws_selected_vpc.id    ###var.vpc_id

ingress {
   description = "Allow All Traffic"
   from_port   = 5432
   to_port     = 5432
   protocol    = "tcp"
   cidr_blocks = ["192.168.0.0/16"]    ### Allow all traffic for AWS VPC CIDR
 }

egress {
   from_port   = 0
   to_port     = 0
   protocol    = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

###################################################### RDS Subnet Group ################################################################## 

# Datasource for VPC Private Subnet
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.aws_selected_vpc.id]
  }

  tags = {
    Name = "Private*"
  }
}

resource "aws_db_subnet_group" "dbsubnet" {
  name = "rds-subnetgroup"
  description = "RDS DB Subnet Group"
  subnet_ids = data.aws_subnets.private.ids   ###var.private_subnets ##You should change this value as per your vpc subnet
}

######################################### Launch RDS PostgreSQL DB Instance ##############################################

resource "aws_db_instance" "dbinstance1" {
  identifier           = "dbinstance-1"
  allocated_storage    = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type         = var.storage_type
  engine               = var.engine
  engine_version       = var.engine_version      ### var.engine_version[11] use for postgresql
  instance_class       = var.instance_class
  db_name              = "demodb"
  username             = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["username"]    ###var.username
  password             = jsondecode(aws_secretsmanager_secret_version.rds_secret_version.secret_string)["password"]    ###var.password
  parameter_group_name = "default.postgres14"
  multi_az             = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]           ###var.vpc_security_group_ids
  db_subnet_group_name = aws_db_subnet_group.dbsubnet.name
  publicly_accessible  = false 
  deletion_protection = false ##SHOULD BE ENABLED FOR PRODUCTION ENVIRONMENT
  storage_encrypted = true
  kms_key_id = var.kms_key_id_rds    ##The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN.
  apply_immediately = true  ##Specifies whether any database modifications are applied immediately, or during the next maintenance window, default is false
  monitoring_role_arn = var.monitoring_role_arn ##arn:aws:iam::0XXXXXXXXXXXXX6:role/rds-monitoring-role
  monitoring_interval = 5 ##The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. The default is 0. Valid Values: 0, 1, 5, 10, 15, 30, 60.
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]  ###    ["audit", "error", "general", "slowquery"] for MySQL
  tags = {         ##use tags as required
  Environment = var.env
  }
}

