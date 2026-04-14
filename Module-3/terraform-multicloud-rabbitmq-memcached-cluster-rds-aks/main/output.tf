output "aks_k8s_management_azure_vm_instance_gcp_vm_instance_details_and_aws_rds_db_instance" {
  description = "Details of created AKS Cluster, K8S Management Azure VM Instance, GCP VM Instance and AWS RDS DB Instance"
  value       = module.aws_azure_gcp_multicloud 
  sensitive   = true
}
