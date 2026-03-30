module "gcp_cloud_dns_zone" {

source = "../module"
project_name = var.project_name
gcp_region = var.gcp_region[1]
prefix = var.prefix
dns_name = var.dns_name
ip_range_subnet = var.ip_range_subnet
ip_public_range_subnet = var.ip_public_range_subnet
ip_proxy_range_subnet = var.ip_proxy_range_subnet
machine_type = var.machine_type
dns_zone_visibility = var.dns_zone_visibility[0]
gcp_vpc_name = var.gcp_vpc_name
gcp_subnet_name = var.gcp_subnet_name
enable_logging = var.enable_logging[0] 
dnssec_state = var.dnssec_state[0] 
env  = var.env[0]

}
