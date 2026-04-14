############################################### Parameters for Azure VNet and Site-to-Site VPN##################################################

prefix = "multicloud"
location = ["East US", "East US 2", "Central India", "Central US"]
env = ["dev", "stage", "prod"]
static_dynamic = ["Static", "Dynamic"]
availability_zone = [1] ### Provide the Availability Zones into which the VM to be created.

#####################################################Provide Parameters for AWS VPC and Site-to-Site VPN########################################

region = "us-east-2"

#prefix = eks

vpc_cidr            = "192.168.0.0/16"
private_subnet_cidr = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
public_subnet_cidr  = ["192.168.4.0/24", "192.168.5.0/24", "192.168.6.0/24"]
private_subnet_tgw_attachment_cidr = ["192.168.7.0/28", "192.168.8.0/28", "192.168.9.0/28"]
igw_name            = "test-IGW"
natgateway_name     = "Dexter-NatGateway"
vpc_name            = "test-vpc"

############################Parameters to create the GCP VPC and Site-to-Site VPN ##################################################

project_name = "XXXX-XXXXXXX-2XXXX6" ### Provide the GCP Account Project ID.

gcp_region = ["us-east1", "us-central1", "asia-south2", "asia-south1", "us-west1"]

ip_range_subnet = "10.10.0.0/20"

master_ip_range = "172.16.0.0/28"

pods_ip_range = "172.17.0.0/16"

services_ip_range = "172.19.0.0/16"

ip_public_range_subnet = "10.20.0.0/20"

###############################################Parameters for AWS and GCP ASN#######################################################

gcp_asn = 65000

aws_asn = 64512

##################################################### Parameters for AKS ###########################################################

kubernetes_version_aks = ["1.26.6", "1.26.10", "1.27.3", "1.27.7", "1.28.0", "1.28.3", "1.28.5", "1.29.0", "1.29.2", "1.30.0", "1.30.12", "1.31.8", "1.32.4", "1.33.0", "1.34.4"]
action_group_shortname = "aks-action"
email_address = "abc@gmail.com"  ### Provide Group Email Address on which notification should be send.

######################################################Parameters to launch EC2####################################################

instance_count = 1
instance_type  = ["t3.micro", "t3.small", "t3.medium"]
provide_ami = {
  "us-east-1" = "ami-0a1179631ec8933d7"
  "us-east-2" = "ami-051de6a4e7ae45f77" ###"ami-0169aa51f6faf20d5"
  "us-west-1" = "ami-0e0ece251c1638797"
  "us-west-2" = "ami-086f060214da77a16"
}
#subnet_id = "subnet-XXXXXXXXXXXXXXXXX"
#vpc_security_group_ids = ["sg-00cXXXXXXXXXXXXX9"]
cidr_blocks = ["0.0.0.0/0"]
name        = "K8S-Management"

kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" ### Provide the ARN of KMS Key.

############################################### RDS DB Instance Parameters ###############################################

  db_instance_count = 1
  identifier = "dbinstance-1"
  db_subnet_group_name = "rds-subnetgroup"        ###  postgresql-subnetgroup
#  rds_subnet_group = ["subnet-XXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXX", "subnet-XXXXXXXXXXXXXX"]
#  read_replica_identifier = "dbinstance-readreplica-1"
  allocated_storage = 20
  max_allocated_storage = 100
#  read_replica_max_allocated_storage = 100
  storage_type = ["gp2", "gp3", "io1", "io2"]
#  read_replica_storage_type = ["gp2", "gp3", "io1", "io2"]
  engine = ["mysql", "mariadb", "mssql", "postgres"]
  engine_version = ["5.7.44", "8.4.5", "8.0.33", "8.0.35", "8.0.36", "10.4.30", "10.5.20", "10.11.6", "10.11.7", "13.00.6435.1.v1", "14.00.3421.10.v1", "15.00.4365.2.v1", "14.9", "14.10", "14.11", "14.15", "15.5", "16.1"] ### For postgresql select version = 14.9 and for MySQL select version = 5.7.44
  instance_class = ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge"]
#  read_replica_instance_class = ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.t3.large", "db.t3.xlarge", "db.t3.2xlarge"]
  rds_db_name = "mydb"
  username = "admin"   ### For MySQL select username as admin and For PostgreSQL select username as postgres
  master_user_secret_kms_key_id = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#  password = "Admin123"          ### "Sonar123" use this password for PostgreSQL
  parameter_group_name = ["default.mysql5.7", "default.mysql8.4", "default.postgres14"]
  multi_az = ["false", "true"]   ### select between true or false
#  read_replica_multi_az = false   ### select between true or false
#  final_snapshot_identifier = "database-1-final-snapshot-before-deletion"   ### Here I am using it for demo and not taking final snapshot while db instance is deleted
  skip_final_snapshot = ["true", "false"]
#  copy_tags_to_snapshot = true   ### Select between true or false
#  availability_zone = ["us-east-2a", "us-east-2b", "us-east-2c"]
  publicly_accessible = ["true", "false"]  #### Select between true or false
#  read_replica_vpc_security_group_ids = ["sg-038XXXXXXXXXXXXc291", "sg-a2XXXXXXca"]
#  backup_retention_period = 7   ### For Demo purpose I am not creating any db backup.
  kms_key_id_rds = "arn:aws:kms:us-east-2:02XXXXXXXXX6:key/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
#  read_replica_kms_key_id = "arn:aws:kms:us-east-2:027XXXXXXX06:key/20XXXXXXf3-aXXc-4XXd-9XX4-24XXXXXXXXXX17"  ### I am not using any read replica here.
  monitoring_role_arn = "arn:aws:iam::02XXXXXXXXX6:role/rds-monitoring-role"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]  ### ["postgresql", "upgrade"]  For PostgreSQL

############################# Parameter for GCP to Azure Site-to-Site Connection #############

azure_bgp_asn = "65515"

############################## Parameter for AWS to Azure Site-to-Site Connection ############

azure_asn = "65516"

############################## Parameter for AWS Application LoadBalancer ####################

s3_bucket_exists = false   ### Select between true and false. It true is selected then it will not create the s3 bucket. 
ssl_policy = ["ELBSecurityPolicy-2016-08", "ELBSecurityPolicy-TLS-1-2-2017-01", "ELBSecurityPolicy-TLS-1-1-2017-01", "ELBSecurityPolicy-TLS-1-2-Ext-2018-06", "ELBSecurityPolicy-FS-2018-06", "ELBSecurityPolicy-2015-05"]
certificate_arn = "arn:aws:acm:us-east-2:02XXXXXXXXX6:certificate/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

############################## Parameter for GCP VM Instance #################################

machine_type = ["n1-standard-1", "e2-small", "e2-medium", "n2-standard-4", "c2-standard-4", "c3-standard-4"]

############################## Parameter for Azure VM Instance ###############################

vm_size = ["Standard_B2s", "Standard_B2ms", "Standard_B4ms", "Standard_DS1_v2"]
admin_username = "ritesh"
admin_password = "Password@#795"

############################ Create the Azure Container Registry #################################

acr_sku  = ["Basic", "Standard", "Premium"]
admin_enabled = false  ##### Select true or false. Default value is false.
