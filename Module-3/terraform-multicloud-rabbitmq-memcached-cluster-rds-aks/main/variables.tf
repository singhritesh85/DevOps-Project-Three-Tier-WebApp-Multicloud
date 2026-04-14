############################################################### Variables for VPC ##################################################################

variable "region" {
  type        = string
  description = "Provide the AWS Region into which EKS Cluster to be created"
}

variable "vpc_cidr" {
  description = "Provide the CIDR for VPC"
  type        = string
  #default = "10.10.0.0/16"
}

variable "private_subnet_cidr" {
  description = "Provide the cidr for Private Subnet"
  type        = list(any)
  #default = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "public_subnet_cidr" {
  description = "Provide the cidr of the Public Subnet"
  type        = list(any)
  #default = ["10.10.3.0/24", "10.10.4.0/24", "10.10.5.0/24"]
}

variable "private_subnet_tgw_attachment_cidr" {
  description = "Provide the cidr for Private Subnet for Transit Gateway Attcahment"
  type        = list(any)
  #default = ["10.10.7.0/28", "10.10.8.0/28", "10.10.9.0/28"]
}

data "aws_partition" "amazonwebservices" {
}

data "aws_region" "reg" {
}

data "aws_availability_zones" "azs" {
}

data "aws_caller_identity" "G_Duty" {
}

variable "igw_name" {
  description = "Provide the Name of Internet Gateway"
  type        = string
  #default = "test-IGW"
}

variable "natgateway_name" {
  description = "Provide the Name of NAT Gateway"
  type        = string
  #default = "EKS-NatGateway"
}

variable "vpc_name" {
  description = "Provide the Name of VPC"
  type        = string
  #default = "test-vpc"
}

variable "env" {
  type        = list(any)
  description = "Provide the Environment for EKS Cluster and NodeGroup"
}

############################################## Variables to create the GCP VPC ############################################################

variable "project_name" {
  description = "Provide the project name in GCP Account"
  type        = string
}

variable "gcp_region" {
  description = "Provide the GCP Region in which Resources to be created"
  type        = list(any)
}

variable "prefix" {
  description = "Provide the prefix used for the project"
  type        = string
}

variable "ip_range_subnet" {
  description = "Provide the IP range for Private Subnet"
  type        = string
}

variable "master_ip_range" {
  description = "Provide GKE Master IP range"
  type = string
}

variable "pods_ip_range" {
  description = "Secondary IP address range using which Pod will be created"
  type        = string
}

variable "services_ip_range" {
  description = "Secondary IP address range using which Services will be created"
  type        = string
}

variable "ip_public_range_subnet" {
  description = "Provide the IP range for Public Subnet"
  type        = string
}

##################################################### Variables for AWS and GCP Site-to-Site VPN ############################################################

variable "gcp_asn" {
  description = "Provide the ASN Number"
  type        = number
}

variable "aws_asn" {
  description = "Provide the ASN Number"
  type        = number
}

###################################################### Variables for Azure VNet and Site-to-Site VPN #######################################################

variable "location" {
  type = list
  description = "Provide the Location for Resources to be created"
}

variable "availability_zone" {
  type = list
  description = "Provide the Availability Zone into which the VM to be created"
}

variable "static_dynamic" {
  type = list
  description = "Select the Static or Dynamic"
}

################################################################ Variables for AKS ####################################################################

variable "kubernetes_version_aks" {
  type = list
  description = "Provide the Kubernetes Version"
}

variable "action_group_shortname" {
  type = string
  description = "Provide the short name for Azure Action Group"
}

variable "email_address" {
  type = string
  description = "Provide the Group Email Address on which Notification should be send"
}

########################################### variables to launch EC2 ############################################################

variable "instance_count" {
  description = "Provide the Instance Count"
  type        = number
}

variable "instance_type" {
  description = "Provide the Instance Type to Launch EC2 Instance"
  type = list
}

variable "provide_ami" {
  description = "Provide the AMI ID for the EC2 Instance"
  type        = map(any)
}

#variable "vpc_security_group_ids" {
#  description = "Provide the security group Ids to launch the EC2"
#  type = list
#}

#variable "subnet_id" {
#  description = "Provide the Subnet ID into which EC2 to be launched"
#  type = string
#}

variable "cidr_blocks" {
  description = "Provide the CIDR Block range"
  type        = list(any)
}

variable "kms_key_id" {
  description = "Provide the KMS Key ID to Encrypt EBS"
  type        = string
}

variable "name" {
  description = "Provide the name of the EC2 Instance"
  type        = string
}

########################################### Variables for RDS #########################################################

variable "identifier" {
  description = "Provide the DB Instance Name"
  type = string
}

variable "db_subnet_group_name" {
  description = "Provide the Name for DB Subnet Group"
  type = string
}

#variable "rds_subnet_group" {
#  description = "Provide the Subnet IDs to create DB Subnet Group"
#  type = list
#}

variable "db_instance_count" {
  description = "Provide the number of DB Instances to be launched"
  type = number
}

#variable "read_replica_identifier" {
#  description = "Provide the Read-Replica DB Instance Name"
#  type = string
#}

variable "allocated_storage" {
  description ="Memory Allocated for RDS"
  type = number
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  type = number
}

#variable "read_replica_max_allocated_storage" {
#  description = "The upper limit to which Amazon RDS Read Replica can automatically scale the storage of the DB instance"
#  type = number
#}

variable "storage_type" {
  description = "storage type of RDS"
  type = list
}

#variable "read_replica_storage_type" {
#  description = "storage type of RDS Read Replica"
#  type = string
#}

variable "engine" {
  description = "Engine of RDS"
  type = list
}

variable "engine_version" {
  description = "Engine Version of RDS"
  type = list
}

variable "instance_class" {
  description = "DB Instance Type"
  type = list
}

#variable "read_replica_instance_class" {
#  description = "DB Instance Type of Read Replica"
#  type = list
#}

variable "rds_db_name" {
  description = "Provide the DB Name"
  type = string
}

variable "username" {
  description = "Provide the Administrator Username fr RDS"
  type = string
}

#variable "password" {
#  description = "Provide the Administrator Password for RDS"
#  type = string
#}

variable "master_user_secret_kms_key_id" {
  description = "Provide the KMS Key ID for AWS Secrets Manager"
  type = string
}

variable "parameter_group_name" {
  description = "Parameter Group Name for RDS"
  type = list
}

variable "multi_az" {
  description = "To enable or disable multi AZ"
  type = list
}

#variable "read_replica_multi_az" {
#  description = "To enable or disable multi AZ"
#  type = list
#}

#variable "final_snapshot_identifier" {
#  description = "Provide the Final Snapshot Name"
#  type = string
#}

variable "skip_final_snapshot" {
  description = "To skip Final Snapshot before deletion"
  type = list
}

#variable "copy_tags_to_snapshot" {
#  description = "Copy Tags to Final Snapshot"
#  type = list
#}

#variable "availability_zone" {    ### Multi AZ is not enabled for RDS
#  description = "Availabilty Zone of the RDS DB Instance"
#  type = list
#}

variable "publicly_accessible" {
  description = "To make RDS publicly Accessible or not"
  type = list
}

#variable "read_replica_vpc_security_group_ids" {
#  description = "List of VPC security groups to br associated with RDS Read Replica"
#  type = list
#}

#variable "backup_retention_period" {
#  description = "The days to retain backups for. Must be between 0 and 35"
#  type = list
#}

variable "kms_key_id_rds" {
  description = "ARN of Kms Key Id to encrypt the RDS Volume"
  type = string
}

#variable "read_replica_kms_key_id" {
#  description = "ARN of Kms Key Id to encrypt the RDS Volume of Read Replica"
#  type = string
#}

variable "monitoring_role_arn" {
  description = "ARN of IAM Role to enable enhanced monitoring"
  type = string
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Which type of Logs to enable"
  type = list
}

######################################################### Variables for Azure to GCP Site to Site Connection ###########################################

variable "azure_bgp_asn" {
  type = number
  description = "Provide ASN Number"
}

######################################################### Variables for AWS to Azure Site to Site Connection ###########################################

variable "azure_asn" {
  type = number
  description = "Provide ASN Number"
}

######################################################## Variables for AWS Application LoadBalancer ####################################################

variable "ssl_policy" {
  description = "Select the SSl Policy for the Application Loadbalancer"
  type = list
}

variable "certificate_arn" {
  description = "Provide the SSL Certificate ARN from AWS Certificate Manager"
  type = string
}

variable "s3_bucket_exists" {
  description = "Create S3 bucket only if doesnot exists."
  type = bool
}

######################################################## Variables to create GCP VM Instance ###########################################################

variable "machine_type" {
  description = "Provide the Machine Type for VM Instances"
  type = list
}

######################################################## Variables to create Azure VM Instance ##########################################################

variable "vm_size" {
  type = list
  description = "Provide the Size of the Azure VM"
}

variable "admin_username" {
  type = string
  description = "Provid the Administrator Username"
}

variable "admin_password" {
  type = string
  description = "Provide the Administrator Password"
}

################################################### Variables to create Azure Container Registry ######################################################

variable "acr_sku" {
  type = list
  description = "Selection the SKU among Basic, Standard and Premium"
}

variable "admin_enabled" {
  type = bool
  description = "The ACR accessibility is Admin enabled or not."
}
