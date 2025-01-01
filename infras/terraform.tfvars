# terraform.tfvars
project_id    = "node-app-go"
region        = "asia-southeast1"
zone          = "asia-southeast1-a"
environment   = "dev"
docker_image  = "gcr.io/node-app-go/node-app-go"

# Cấu hình cluster
cluster_name    = "optimized-cluster"
network_name    = "gke-network"
subnet_name     = "gke-subnet"
subnet_cidr     = "10.0.0.0/24"
node_pool_name  = "optimized-node-pool"
min_node_count  = 1
max_node_count  = 2
machine_type    = "e2-small"
disk_size_gb    = 20

