output "k8s_management_instance_id" {
  description = "The ID of the K8S Management EC2 instance."
  value       = aws_instance.k8s_management.id
}
output "k8s_management_private_ip" {
  description = "The private IP address of the K8S Management EC2 instance."
  value       = aws_instance.k8s_management.private_ip
}
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.eksdemo.endpoint
}
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eksdemo.name
}
output "karpenter_node_spun_iam_role_arn" {
  description = "IAM Role ARN for Karpenter to spin-up nodes"
  value       = aws_iam_role.karpenter_node_iam_role.arn
}
output "azure_mysql_flexible_server_fqdn" {
  description = "FQDN of the Azure MySQL Flexible server"
  value       = azurerm_mysql_flexible_server.azure_mysql.fqdn
}
output "azure_mysql_flexible_server_name" {
  description = "The name of the Azure MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.azure_mysql.name
}
output "gcp_memcached_instance_private_ip" {
  description = "The private IP address of the Memcached GCP VM Instance"
  value       = google_compute_instance.vm_instance_memcached.network_interface[0].network_ip
}
output "gcp_rabbitmq_instances_private_ip" {
  description = "The private IP address of the RabbitMQ GCP VM Instances"
  value       = google_compute_instance.vm_instance[*].network_interface[0].network_ip
}

