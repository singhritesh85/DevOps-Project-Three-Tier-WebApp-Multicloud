############################################################# Variables for AWS VPC ###############################################################

variable "vpc_cidr"{

}

variable "private_subnet_cidr"{

}

variable "public_subnet_cidr"{

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

################################################################ Variables for EKS ##########################################################################

variable "eks_cluster" {

}

variable "eks_iam_role_name" {

}

variable "node_group_name" {

}

variable "eks_nodegrouprole_name" {

}

variable "launch_template_name" {

}

variable "instance_type" {

}

#variable "eks_ami_id" {

#}

variable "disk_size" {

}

variable "capacity_type" {

}

variable "ami_type" {

}

variable "release_version" {

}

variable "kubernetes_version" {

}

variable "ebs_csi_name" {

}

variable "ebs_csi_version" {

}

variable "csi_snapshot_controller_version" {

}

variable "addon_version_guardduty" {

}

variable "addon_version_kubeproxy" {

}

variable "addon_version_vpc_cni" {

}

variable "addon_version_coredns" {

}

variable "addon_version_observability" {

}

variable "addon_version_podidentityagent" {

}

variable "addon_version_metrics_server" {

}

################################################################ variables to launch EC2 ################################################################

variable "instance_count" {

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

################################################################## Variables for GCP Redis Cluster #####################################################

variable "shard_count" {

}

variable "replica_count" {

}

################################################## Username and Password for Azure PostgreSQL Flexible Servers #########################################

variable "mysql_server_admin_username" {

}

######################################################### Variables for Azure to GCP Site to Site Connection ###########################################

variable "azure_bgp_asn" {

}  

######################################################### Variables for AWS to Azure Site to Site Connection ###########################################

variable "azure_asn" {

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

