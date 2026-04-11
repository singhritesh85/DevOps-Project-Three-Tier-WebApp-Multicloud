output "eks_gke_aks_k8s_management_instance_azure_vm_instance_and_gcp_vm_instance" {
  description = "Details of created EKS Cluster, GKE Cluster, AKS Cluster, K8S Management Node, Azure VM Instance and GCP VM Instance"
  value       = module.aws_azure_gcp_multicluster 
  sensitive   = true
}
