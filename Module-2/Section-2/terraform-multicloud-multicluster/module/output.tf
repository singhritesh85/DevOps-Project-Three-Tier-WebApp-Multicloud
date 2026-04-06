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
output "gke_cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.gke_cluster.name
}
output "gke_cluster_endpoint" {
  description = "GKE cluster Endpoint"
  value       = google_container_cluster.gke_cluster.endpoint
}
output "aks_cluster_name" {
  description = "Name of the GKE cluster"
  value       = azurerm_kubernetes_cluster.aks_cluster.name
}
output "aks_cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.aks_cluster.id
}
output "azure_vm_instance_private_ip" {
  description = "The private IP address of the Azure VM instance."
  value       = azurerm_linux_virtual_machine.azure_vm_k8s_management_node.private_ip_address
}
output "gcp_vm_instance_private_ip" {
  description = "The private IP address of the GCP VM instance."
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}
output "azure_vm_instance_name" {
  description = "Name of the Azure VM instance."
  value       = azurerm_linux_virtual_machine.azure_vm_k8s_management_node.name
}
output "gcp_vm_instance_name" {
  description = "Name of the GCP VM instance."
  value       = google_compute_instance.vm_instance.name
}
