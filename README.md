# Golden Owl DevOps Internship - Node.js Application Deployment with GKE

This project demonstrates a complete CI/CD pipeline for deploying a Node.js application to Google Kubernetes Engine (GKE) using GitHub Actions and Terraform.

## Infrastructure Overview

- VPC Network with custom subnet and private Google access

- GKE Cluster configuration:
  - VPC-native networking
  - Workload identity enabled
  - Network policy with Calico
  - Private cluster capability
  - Regular release channel for updates

- Node Pool features:
  - Spot instances for cost optimization
  - Autoscaling (1-10 nodes)
  - Automatic upgrades and repairs
  - COS_CONTAINERD image type

- Kubernetes Resources:
  - Deployment with health probes
  - Horizontal Pod Autoscaler (CPU-based)
  - LoadBalancer Service

![deploy-node-app-go.drawio.svg](deploy-node-app-go.drawio.svg)

## CI/CD Pipeline
### Continuous Integration (CI)
- Triggers on:
  - Push to master branch
  - Pull request to master
  - Manual workflow dispatch

- Build Stage:
  - Checks out code
  - Authenticates with Google Cloud
  - Builds Docker image
  - Pushes to Google Container Registry

### Continuous Deployment (CD)
- Deploy Stage:
  - Authenticates with GKE cluster
  - Updates deployment with new image
  - Zero-downtime rolling updates

### Prerequisites
- Google Cloud Platform account
- GitHub repository
- Google Cloud SDK
- Terraform CLI

### Setup steps
1. Configure GitHub Secrets
```angular2html
GCP_SA_KEY           # Google Cloud Service Account key
GCP_PROJECT_ID       # Google Cloud Project ID
GCP_ZONE            # GKE cluster zone
```
2. Deploy Infrastructure
```angular2html
cd infras
terraform init
terraform plan
terraform apply
```
3. Run CI/CD Pipeline

Run the GitHub Actions workflow manually or push to master branch:
```angular2html
git push origin master
```
