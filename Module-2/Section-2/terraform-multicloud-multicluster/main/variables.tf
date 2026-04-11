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
  #default = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
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
  description = "IP address range for the master network of a GKE cluster"
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

################################################################ Variables for EKS ####################################################################

variable "eks_cluster" {
  type        = string
  description = "Provide the EKS Cluster Name"
}

variable "eks_iam_role_name" {
  type        = string
  description = "Provide the EKS IAM Role Name"
}

variable "node_group_name" {
  type        = string
  description = "Provide the Node Group Name"
}

variable "eks_nodegrouprole_name" {
  type        = string
  description = "Provide the Node Group Role Name"
}

variable "launch_template_name" {
  type        = string
  description = "Provide the Launch Template Name"
}

#variable "eks_ami_id" {
#  type = list
#  description = "Provide the EKS AMI ID"
#}

variable "instance_type" {
  type        = list(any)
  description = "Provide the Instance Type EKS Worker Node"
}

variable "disk_size" {
  type        = number
  description = "Provide the EBS Disk Size"
}

variable "capacity_type" {
  type        = list(any)
  description = "Provide the Capacity Type of Worker Node"
}

variable "ami_type" {
  type        = list(any)
  description = "Provide the AMI Type"
}

variable "release_version" {
  type        = list(any)
  description = "AMI version of the EKS Node Group"
}

variable "kubernetes_version" {
  type        = list(any)
  description = "Desired Kubernetes master version."
}

variable "ebs_csi_name" {
  type        = string
  description = "Provide the addon name"
}

variable "ebs_csi_version" {
  type        = list(any)
  description = "Provide the ebs csi driver version"
}

variable "csi_snapshot_controller_version" {
  type        = list(any)
  description = "Provide the csi snapshot controller version"
}

variable "addon_version_guardduty" {
  type        = list(any)
  description = "Provide the addon version for Guard Duty"
}

variable "addon_version_kubeproxy" {
  type        = list(any)
  description = "Provide the addon version for kube-proxy"
}

variable "addon_version_vpc_cni" {
  type        = list(any)
  description = "Provide the addon version for VPC-CNI"
}

variable "addon_version_coredns" {
  type        = list(any)
  description = "Provide the addon version for core-dns"
}

variable "addon_version_observability" {
  type        = list(any)
  description = "Provide the addon version for observability"
}

variable "addon_version_podidentityagent" {
  type        = list(any)
  description = "Provide the addon version for Pod Identity Agent"
}

variable "addon_version_metrics_server" {
  type        = list(any)
  description = "Provide the addon version for Metrics Server"
}

########################################### variables to launch EC2 ############################################################

variable "instance_count" {
  description = "Provide the Instance Count"
  type        = number
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

################################################## Username and Password for Azure MySQL Flexible Servers #########################################

variable "mysql_server_admin_username" {
  type = string
  description = "Provide the username for MySQL Flexible Server"
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

####################################################### Variables to create Azure AKS Cluster #########################################################

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

##################################################### Variables to create GKE Cluster in GCP ###########################################################

variable "min_master_version" {
  description = "Provide Kubernetes Version of Control Plane"
  type = list
}

variable "node_version" {
  description = "Provide Kubernetes Version of Worker Nodes"
  type = list
}
