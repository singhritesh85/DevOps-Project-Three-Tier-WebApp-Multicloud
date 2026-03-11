module "aws_azure_gcp_multicluster" {

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
  igw_name            = var.igw_name
  natgateway_name     = var.natgateway_name
  vpc_name            = var.vpc_name

############################Parameters to create the GCP VPC and Site-to-Site VPN ##################################################

  project_name = var.project_name
  gcp_region = var.gcp_region[1]
  ip_range_subnet = var.ip_range_subnet
  pods_ip_range = var.pods_ip_range
  services_ip_range = var.services_ip_range
  ip_public_range_subnet = var.ip_public_range_subnet

###############################################Parameters for AWS and GCP ASN#######################################################

  gcp_asn = var.gcp_asn
  aws_asn = var.aws_asn

eks_cluster            = var.eks_cluster
  eks_iam_role_name      = var.eks_iam_role_name
  node_group_name        = var.node_group_name
  eks_nodegrouprole_name = var.eks_nodegrouprole_name
  launch_template_name   = var.launch_template_name
  #  eks_ami_id = var.eks_ami_id
  instance_type      = var.instance_type
  disk_size          = var.disk_size
  ami_type           = var.ami_type
  release_version    = var.release_version
  kubernetes_version = var.kubernetes_version
  capacity_type      = var.capacity_type
  ebs_csi_name       = var.ebs_csi_name

  ebs_csi_version                 = var.ebs_csi_version[0]
  csi_snapshot_controller_version = var.csi_snapshot_controller_version[0]
  addon_version_guardduty         = var.addon_version_guardduty[0]
  addon_version_kubeproxy         = var.addon_version_kubeproxy[0]
  addon_version_vpc_cni           = var.addon_version_vpc_cni[0]
  addon_version_coredns           = var.addon_version_coredns[0]
  addon_version_observability     = var.addon_version_observability[0]
  addon_version_podidentityagent  = var.addon_version_podidentityagent[0]
  addon_version_metrics_server    = var.addon_version_metrics_server[0]

  ###########################To Launch EC2###################################

  instance_count = var.instance_count
  provide_ami    = var.provide_ami["us-east-2"]
  #  vpc_security_group_ids = var.vpc_security_group_ids
  cidr_blocks = var.cidr_blocks
  #  subnet_id = var.subnet_id
  kms_key_id = var.kms_key_id
  name       = var.name

  ##########################To create GCP Redis Cluster #####################

  shard_count = var.shard_count
  replica_count = var.replica_count

  ############################ Create MySQL Flexible Servers ###################################

  mysql_server_admin_username = var.mysql_server_admin_username

  ############################## To create GCP to Azure Site to Site Connection ################

  azure_bgp_asn = var.azure_bgp_asn

  ################################# To create AWS to Azure Site to Site Connection #############

  azure_asn = var.azure_asn

  ################################# To create GCP VM Instance ##################################

  machine_type = var.machine_type[2]

  ############################### To create Azure VM Instance ##################################
  
  vm_size = var.vm_size[0]
  admin_username = var.admin_username
  admin_password = var.admin_password

}  
