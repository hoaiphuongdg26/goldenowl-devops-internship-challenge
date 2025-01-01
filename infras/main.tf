# main.tf
# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Get Google client config for Kubernetes provider
data "google_client_config" "default" {}

# VPC Network
resource "google_compute_network" "vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = var.subnet_name
  ip_cidr_range = var.subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id

  # Enable private Google access
  private_ip_google_access = true

  # Enable flow logs for better networking visibility
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling       = 0.5
    metadata           = "INCLUDE_ALL_METADATA"
  }
}

# GKE cluster configuration
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.zone
  deletion_protection = false

  # Remove default node pool after cluster creation
  remove_default_node_pool = true
  initial_node_count       = 1

  # Use the latest stable release channel
  release_channel {
    channel = "REGULAR"
  }

  # Enable network policy
  network_policy {
    enabled = true
    provider = "CALICO"
  }

  # Use VPC-native cluster
  networking_mode = "VPC_NATIVE"

  network    = google_compute_network.vpc.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  # Enable workload identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  master_authorized_networks_config {
    # cidr_blocks {
    #   cidr_block   = "116.110.43.12/32"
    #   display_name = "My IP"
    # }
    # cidr_blocks {
    #   cidr_block   = var.subnet_cidr
    #   display_name = "VPC"
    # }
    cidr_blocks {
        cidr_block   = "0.0.0.0/0"
        display_name = "Allow all"
    }
  }

  # Enable private cluster
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
    # master_ipv4_cidr_block = "172.16.0.0/28"
  }

  # Required ip_allocation_policy for VPC_NATIVE clusters
  ip_allocation_policy {
    cluster_ipv4_cidr_block = "10.8.0.0/14"
    services_ipv4_cidr_block = "10.12.0.0/20"
  }
}

# Node pool (no need for workload_identity_config here anymore)
resource "google_container_node_pool" "primary_nodes" {
  name       = var.node_pool_name
  location   = var.zone
  cluster    = google_container_cluster.primary.name

  initial_node_count = var.min_node_count

  # Enable autoscaling
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Node configuration
  node_config {
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    image_type   = "COS_CONTAINERD"

    # Use spot instances
    spot = true

    # Minimal set of OAuth scopes
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]

    labels = {
      environment = var.environment
    }

    # Add required metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  # Enable automatic upgrades and repairs
  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "app" {
  metadata {
    name = "node-app-go"
    labels = {
      app = "node-app-go"
      environment = var.environment
    }
  }

  spec {
    replicas = var.min_node_count

    selector {
      match_labels = {
        app = "node-app-go"
      }
    }

    template {
      metadata {
        labels = {
          app = "node-app-go"
          environment = var.environment
        }
      }

      spec {
        container {
          image = var.docker_image
          name  = "node-app-go"

          port {
            container_port = 3000
          }

          # Add liveness probe
          liveness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds       = 10
          }

          # Add readiness probe
          readiness_probe {
            http_get {
              path = "/"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds       = 5
          }
        }
      }
    }
  }
  lifecycle {
    create_before_destroy = true
  }

  wait_for_rollout = false
  depends_on = [google_container_node_pool.primary_nodes]
}

# HPA configuration
resource "kubernetes_horizontal_pod_autoscaler_v2" "app_hpa" {
  metadata {
    name = "node-app-go-hpa"
  }

  spec {
    max_replicas = 5
    min_replicas = 1

    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.app.metadata[0].name
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 70
        }
      }
    }
  }
}

# Service configuration
resource "kubernetes_service" "app" {
  metadata {
    name = "node-app-go-service"
    labels = {
      app = "node-app-go"
      environment = var.environment
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.app.spec[0].template[0].metadata[0].labels.app
    }

    port {
      name        = "http"
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}