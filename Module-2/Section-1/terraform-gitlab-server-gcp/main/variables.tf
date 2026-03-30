########################################### Variables to create Cloud DNS Zone ################################################

variable "project_name" {
  description = "Provide the project name in GCP Account"
  type = string
}

variable "gcp_region" {
  description = "Provide the GCP Region in which Resources to be created"
  type = list
}

variable "prefix" {
  type = string
  description = "Provide a prefix name for GCP Cloud DNS Zone to be created"
}

variable "dns_name" {
  description = "Provide the name of the Cloud DNS Zone"
  type = string
}

variable "dns_zone_visibility" {
  description = "Select the DNS Zone Visibility between Public and Private"
  type = list
}

variable "gcp_vpc_name" {
  description = "Provide the GCP VPC Name into which the GitLab Server needs to be created"
  type = string
}

variable "gcp_subnet_name" {
  description = "Provide the GCP Subnet Name into which the GitLab Server needs to be created"
  type = string
}

variable "ip_range_subnet" {
  description = "Provide the IP range for Private Subnet"
  type = string 
}

variable "ip_public_range_subnet" {
  description = "Provide the IP range for Public Subnet"
  type = string
}

variable "ip_proxy_range_subnet" {
  description = "Provide the IP range for Proxy Subnet will be used by GCP ALB"
  type = string
}

variable "machine_type" {
  description = "Provide the Machine Type for VM Instances"
  type = list
}

variable "enable_logging" {
  description = "Select do you want to enable or disable the logging"
  type = list
}

variable "dnssec_state" {
  description = "Select do you want to enable or disable the dnssec"
  type = list
}

variable "env" {
  description = "Provide the Environment Name."
  type = list
}
