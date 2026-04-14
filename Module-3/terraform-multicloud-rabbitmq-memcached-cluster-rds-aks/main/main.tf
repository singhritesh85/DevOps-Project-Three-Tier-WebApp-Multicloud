module "aws_azure_gcp_multicloud" {

  source = "../module"
  prefix = var.prefix
  location = var.location[0]
  env = var.env[0]
  static_dynamic = var.static_dynamic 
  availability_zone = var.availability_zone[0]

#####################################################Provide Parameters for AWS VPC and Site-to-Site VPN########################################

  vpc_cidr            = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_tgw_attachment_cidr = var.private_subnet_tgw_attachment_cidr
  igw_name            = var.igw_name
  natgateway_name     = var.natgateway_name
  vpc_name            = var.vpc_name

############################Parameters to create the GCP VPC and Site-to-Site VPN ##################################################

  project_name = var.project_name
  gcp_region = var.gcp_region[1]
  ip_range_subnet = var.ip_range_subnet
  master_ip_range = var.master_ip_range
  pods_ip_range = var.pods_ip_range
  services_ip_range = var.services_ip_range
  ip_public_range_subnet = var.ip_public_range_subnet

###############################################Parameters for AWS and GCP ASN#######################################################

  gcp_asn = var.gcp_asn
  aws_asn = var.aws_asn

  ###########################To Launch EC2###################################

  instance_count = var.instance_count
  instance_type  = var.instance_type
  provide_ami    = var.provide_ami["us-east-2"]
  #  vpc_security_group_ids = var.vpc_security_group_ids
  cidr_blocks = var.cidr_blocks
  #  subnet_id = var.subnet_id
  kms_key_id = var.kms_key_id
  name       = var.name

  ############################################### For RDS ##############################################################

#  count = var.db_instance_count
  identifier = var.identifier
  db_subnet_group_name = var.db_subnet_group_name
#  rds_subnet_group = var.rds_subnet_group
#  read_replica_identifier = var.read_replica_identifier  ###  read_replica_identifier = "${var.read_replica_identifier}-${count.index + 1}"
  allocated_storage = var.allocated_storage
#  password = var.password
  max_allocated_storage = var.max_allocated_storage
#  read_replica_max_allocated_storage = var.read_replica_max_allocated_storage
  storage_type = var.storage_type[0]
#  read_replica_storage_type = var.read_replica_storage_type
  engine = var.engine[0]             ### var.engine[3]  use for PostgreSQL
  engine_version = var.engine_version[1]       ### var.engine_version[14]  use for PostgreSQL
  instance_class = var.instance_class[0]
#  read_replica_instance_class = var.read_replica_instance_class
  rds_db_name = var.rds_db_name
  username = var.username
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id
  parameter_group_name = var.parameter_group_name[1]
  multi_az = var.multi_az[0]
#  read_replica_multi_az = var.read_replica_multi_az
#  final_snapshot_identifier = var.final_snapshot_identifier
  skip_final_snapshot = var.skip_final_snapshot[0]
#  copy_tags_to_snapshot = var.copy_tags_to_snapshot
#  availability_zone = var.availability_zone[0]  ### It should not be enabled for Multi-AZ option, If it is not enabled for Single DB Instance then it's value will be taken randomly.
  publicly_accessible = var.publicly_accessible[1]
#  read_replica_vpc_security_group_ids = var.read_replica_vpc_security_group_ids
#  backup_retention_period = var.backup_retention_period
  kms_key_id_rds = var.kms_key_id_rds
#  read_replica_kms_key_id = var.read_replica_kms_key_id
  monitoring_role_arn = var.monitoring_role_arn
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  ############################## To create GCP to Azure Site to Site Connection ################

  azure_bgp_asn = var.azure_bgp_asn

  ################################# To create AWS to Azure Site to Site Connection #############

  azure_asn = var.azure_asn

  ################################# To create AWS Application ALB ##############################

  ssl_policy = var.ssl_policy[0]
  certificate_arn = var.certificate_arn
  s3_bucket_exists = var.s3_bucket_exists

  ################################# To create GCP VM Instance ##################################

  machine_type = var.machine_type[2]

  ############################### To create Azure VM Instance ##################################
  
  vm_size = var.vm_size[0]
  admin_username = var.admin_username
  admin_password = var.admin_password

  #################################### To create AKS Cluster ###################################

  kubernetes_version_aks = var.kubernetes_version_aks[14]
  action_group_shortname = var.action_group_shortname
  email_address = var.email_address

  ############################ Create the Azure Container Registry #################################

  acr_sku = var.acr_sku[2]
  admin_enabled = var.admin_enabled

}  
