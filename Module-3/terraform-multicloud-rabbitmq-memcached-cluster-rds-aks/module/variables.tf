############################################################# Variables for AWS VPC ###############################################################

variable "vpc_cidr"{

}

variable "private_subnet_cidr"{

}

variable "public_subnet_cidr"{

}

variable "private_subnet_tgw_attachment_cidr" {

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

}

variable "natgateway_name" {

}

variable "vpc_name" {

}

variable "env" {

}

############################################################ variables to create GCP VPC ############################################################ 

variable "project_name" {

}

variable "gcp_region" {

}

variable "prefix" {

}

variable "ip_range_subnet" {

}

variable "master_ip_range" {

}

variable "pods_ip_range" {

}  

variable "services_ip_range" {

}

variable "ip_public_range_subnet" {

}

##################################################### Variables for AWS and GCP Site-to-Site VPN ############################################################

variable "gcp_asn" {

}

variable "aws_asn" {

}  

#################################################### Variable for Azure VNet ################################################################################

variable "location" {

}

variable "availability_zone" {

}

variable "static_dynamic" {

}

################################################################ Variables for AKS ##########################################################################


variable "kubernetes_version_aks" {

}

variable "action_group_shortname" {

}

variable "email_address" {

}

################################################################ variables to launch EC2 ################################################################

variable "instance_count" {

}

variable "instance_type" {

}

variable "provide_ami" {

}

#variable "vpc_security_group_ids" {

#}

#variable "subnet_id" {

#}

variable "kms_key_id" {

}

variable "cidr_blocks" {

}

variable "name" {

}

############################################################### Variables for RDS ######################################################################

variable "identifier" {

}

variable "db_subnet_group_name" {

}

#variable "rds_subnet_group" {

#}

#variable "read_replica_identifier" {

#}

variable "allocated_storage" {

}

variable "max_allocated_storage" {

}

#variable "read_replica_max_allocated_storage" {

#}

variable "storage_type" {

}

#variable "read_replica_storage_type" {

#}

variable "engine" {

}

variable "engine_version" {

}

variable "instance_class" {

}

#variable "read_replica_instance_class" {

#}

variable "rds_db_name" {

}

variable "username" {

}

#variable "password" {

#}

variable "master_user_secret_kms_key_id" {

}

variable "parameter_group_name" {

}

variable "multi_az" {

}

#variable "read_replica_multi_az" {

#}

#variable "final_snapshot_identifier" {

#}

variable "skip_final_snapshot" {

}

#variable "copy_tags_to_snapshot" {

#}

#variable "availability_zone" {  ### Multi Az in not enabled for RDS

#}

variable "publicly_accessible" {

}

#variable "read_replica_vpc_security_group_ids" {

#}

#variable "backup_retention_period" {

#}

variable "kms_key_id_rds" {

}

#variable "read_replica_kms_key_id" {

#}

variable "monitoring_role_arn" {

}

variable "enabled_cloudwatch_logs_exports" {

}

######################################################### Variables for Azure to GCP Site to Site Connection ###########################################

variable "azure_bgp_asn" {

}  

######################################################### Variables for AWS to Azure Site to Site Connection ###########################################

variable "azure_asn" {

}

######################################################## Variables for AWS Application LoadBalancer ####################################################

variable "ssl_policy" {

}

variable "certificate_arn" {

}

variable "s3_bucket_exists" {

}

######################################################## Variables to create GCP VM Instance ###########################################################

variable "machine_type" {

}

######################################################## Variables to create Azure VM Instance ##########################################################

variable "vm_size" {

}

variable "admin_username" {

}

variable "admin_password" {

}

################################################### Variables to create Azure Container Registry ######################################################

variable "acr_sku" {

}

variable "admin_enabled" {

}
