output "eks_k8s_management_instance_gcp_redis_cluster_and_azure_mysql_flexible_server" {
  description = "Details of created EKS Cluster, K8S Management Node, GCP Redis Cluster and Azure MySQL Flexible Server"
  value       = module.aws_azure_gcp_multicluster 
  sensitive   = true
}
