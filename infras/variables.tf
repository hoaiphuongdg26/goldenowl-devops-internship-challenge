# variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-southeast1-a"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "optimized-cluster"
}

variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "gke-network"
}

variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "gke-subnet"
}

variable "subnet_cidr" {
  description = "Subnet CIDR"
  type        = string
  default     = "10.0.0.0/24"
}

variable "node_pool_name" {
  description = "GKE node pool name"
  type        = string
  default     = "optimized-node-pool"
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Size of the disk attached to each node"
  type        = number
  default     = 10
}

variable "docker_image" {
  description = "Docker image to deploy"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}