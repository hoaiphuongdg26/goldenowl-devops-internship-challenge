# outputs.tf
output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "load_balancer_ip" {
  description = "Load balancer IP address"
  value       = kubernetes_service.app.status.0.load_balancer.0.ingress.0.ip
}

output "node_pool_name" {
  description = "Name of the GKE node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "vpc_network" {
  description = "The VPC network created"
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "The subnet created"
  value       = google_compute_subnetwork.subnet.name
}