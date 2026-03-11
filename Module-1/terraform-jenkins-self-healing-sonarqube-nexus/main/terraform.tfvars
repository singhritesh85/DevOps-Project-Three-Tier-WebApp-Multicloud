################################## Parameters to create the infrastructure ######################################

region = "us-east-2"
project_name = "XXXX-XXXXXXX-2XXXX6"
cidr_blocks = ["0.0.0.0/0"]
s3_bucket_exists = false
access_log_bucket = "s3bucketcapturealblog"
env = ["dev", "stage", "prod"]
public_subnets = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"] 
private_subnets = ["subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXXXX"]
vpc_id = "vpc-XXXXXXXXXXXXXXXXX"
ssl_policy = ["ELBSecurityPolicy-2016-08", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01", "ELBSecurityPolicy-TLS-1-2-Ext-2018-06", "ELBSecurityPolicy-FS-2018-06", "ELBSecurityPolicy-2015-05"]
service_linked_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
###certificate_arn = "arn:aws:acm:us-east-2:02XXXXXXXXX6:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXXX6:key/XXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-09256c524fab91d36"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
instance_type = [ "t3.micro", "t3.small", "t3.medium", "t3.large", "t3.xlarge" ]
allocated_storage = 20
max_allocated_storage = 100
storage_type = ["gp2", "gp3", "io1", "io2"]
engine = ["mysql", "mariadb", "mssql", "postgres"]
engine_version = ["5.7.44", "8.0.33", "8.0.35", "8.0.36", "10.4.30", "10.5.20", "10.11.6", "10.11.7", "13.00.6435.1.v1", "14.00.3421.10.v1", "15.00.4365.2.v1", "14.9", "14.10", "14.11", "14.15", "15.5", "16.1"]
instance_class = ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge"]
kms_key_id_rds = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
monitoring_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/rds-monitoring-role"
username = "postgres"
master_user_secret_kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
managed_zone_name = "multicloud-public-zone"
sq_username = "sonarqube"
sq_password = "'Cloud#436'"
