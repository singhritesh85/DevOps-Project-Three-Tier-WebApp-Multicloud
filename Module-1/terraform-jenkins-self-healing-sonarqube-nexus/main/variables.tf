variable "region" {
  description = "Provide the AWS Region into which the Resources to be created"
  type = string
}  

variable "project_name" {
  description = "Provide the project name in GCP Account"
  type = string
}

variable "cidr_blocks" {
  description = "Provide the CIDR Block range"
  type = list
}

variable "s3_bucket_exists" {
  description = "Create S3 bucket only if doesnot exists."
  type = bool
}

variable "service_linked_role_arn" {
  description = "Provide the service linked role arn"
  type = string
}

variable "access_log_bucket" {
  description = "S3 bucket to capture Application LoadBalancer"
  type = string
}

variable "env" {
  type = list
  description = "Provide the Environment for AWS Resources to be created"
}

variable "vpc_name" {
  description = "Provide the VPC Name"
  type = string
}

#variable "public_subnets" {
#  description = "Provide the Public Subnet IDs of VPC"
#  type = list
#}

#variable "private_subnets" {
#  description = "Provide the Private Subnet IDs of VPC"
#  type = list
#}

#variable "vpc_id" {
#  description = "Provide the VPC ID"
#  type = string
#}

variable "ssl_policy" {
  description = "Select the SSl Policy for the Application Loadbalancer"
  type = list
}

#variable "certificate_arn" {
#  description = "Provide the SSL Certificate ARN from AWS Certificate Manager"
#  type = string
#}

variable "provide_ami" {
  description = "Provide the AMI ID for the EC2 Instance"
  type = map
}

variable "kms_key_id" {
  description = "Provide the ARN for KMS ID to encrypt EBS"
  type = string
}

variable "instance_type" {
  type = list
  description = "Provide the Instance Type EKS Worker Node" 
}

variable "allocated_storage" {
  description ="Memory Allocated for RDS"
  type = number
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
  type = number
}

variable "storage_type" {
  description = "storage type of RDS"
  type = list
}

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

variable "kms_key_id_rds" {
  description = "ARN of Kms Key Id to encrypt the RDS Volume"
  type = string
}

variable "monitoring_role_arn" {
  description = "ARN of IAM Role to enable enhanced monitoring"
  type = string
}

variable "username" {
  description = "Provide the Administrator Username fr RDS"
  type = string
} 

variable "master_user_secret_kms_key_id" {
  description = "Provide the KMS Key ID for AWS Secrets Manager"
  type = string
}  

variable "managed_zone_name" {
  description = "Provide the GCP Cloud DNS Managed Zone Name"
  type = string
}

variable "sq_username" {
  description = "Provide the username for sonarqube database"
  type = string
}

variable "sq_password" {
  description = "Provide the password for sonarqube database"
  type = string
}
