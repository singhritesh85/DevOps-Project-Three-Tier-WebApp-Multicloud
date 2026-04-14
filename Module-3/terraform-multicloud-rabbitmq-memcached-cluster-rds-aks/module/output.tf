output "k8s_management_instance_ip" {
  description = "The Private IP of the K8S Management Azure VM Instance."
  value       = azurerm_network_interface.vnet_interface_k8s_management_node.private_ip_address
}
output "k8s_management_public_ip" {
  description = "The public IP address of the K8S Management Azure VM instance."
  value       = azurerm_public_ip.public_ip_k8s_management_node.ip_address
}
output "aks_cluster_endpoint" {
  description = "Endpoint for Azure AKS Cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.fqdn
}
output "aks_cluster_name" {
  description = "Name of the Azure AKS cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}
output "aws_rds_endpoint" {
  description = "Endpoint of AWS RDS"
  value       = aws_db_instance.dbinstance1.endpoint
}
output "aws_rds_name" {
  description = "The name of the AWS RDS DB Instance"
  value       = aws_db_instance.dbinstance1.id
}
output "gcp_vm_instance_private_ip" {
  description = "GCP VM Instance Private IP"
  value       = google_compute_instance.vm_instance_memcached[*].network_interface[0].network_ip
}
output "gcp_vm_instance_name" {
  description = "GCP VM Instance Name"
  value       = google_compute_instance.vm_instance_memcached[*].name
}
