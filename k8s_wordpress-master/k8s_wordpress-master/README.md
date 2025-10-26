Kubernetes WordPress Deployment (Local Environment)

This guide provides instructions for deploying a production-grade WordPress application, including MySQL and a Lua-enabled OpenResty Nginx proxy, on a local Kubernetes cluster (like Minikube or Docker Desktop).

Project Objectives (Infra Intern Assignment)

Run a production-grade WordPress app on Kubernetes using Helm.

Use PersistentVolumeClaims (PVCs) for stateful components (MySQL, WordPress files).

Use OpenResty Nginx as a proxy with custom Lua configuration.

Set up Prometheus and Grafana for monitoring and alerting.

Prerequisites

Ensure the following tools are installed and configured on your local machine:

Local Kubernetes Cluster: Install and start either Minikube or Docker Desktop (with Kubernetes enabled).

kubectl: Kubernetes command-line tool.

helm: Kubernetes package manager.

Docker: For building and managing container images.

Git: For version control.

Deployment Guide: WordPress Application

This section handles the deployment of MySQL, WordPress, and Nginx (Objective #1).

Step 1: Start Kubernetes and Configure Docker Environment

Start your chosen local Kubernetes cluster and connect your local shell's Docker commands to it.

# 1. Start Minikube (or ensure Docker Desktop Kubernetes is running)
minikube start

# 2. Point your local Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)


Step 2: Build and Load Docker Images Locally

We will build the container images and load them directly into the cluster's image cache, avoiding the need to push to Docker Hub.

Ensure you run these commands from the root directory of the project, where the dockerfiles folder resides.

# Note: Image names must match the values in wordpress-chart/values.yaml
# 1. Build WordPress Image
sudo docker build -t yashingole1000/wordpress-image:latest -f dockerfiles/wordpress.dockerfile .

# 2. Build MySQL Image
sudo docker build -t yashingole1000/mysql-image:latest -f dockerfiles/mysql.dockerfile .

# 3. Build Nginx Image (OpenResty with Lua modules)
# The build context is specified as the nginx folder.
sudo docker build -t yashingole1000/my-nginx:latest -f dockerfiles/nginx/Dockerfile dockerfiles/nginx


Step 3: Install the WordPress Helm Chart

Use Helm to deploy the application stack. All cloud-specific PVC and service configurations have been corrected in the template files to work locally.

# Install the chart using the release name 'my-release'
helm install my-release ./wordpress-chart

# Verify that all components are starting up (wait for STATUS to be Running)
kubectl get pods -w


Step 4: Access the WordPress Application

The Nginx Service is exposed via NodePort. Use the minikube service command to get the external URL.

# Get the external URL for the Nginx proxy (which forwards to WordPress)
minikube service my-release-nginx --url


Paste the resulting URL (http://<ip>:<port>) into your browser to complete the WordPress setup.

Deployment Guide: Monitoring and Alerting

This section handles the deployment of the Prometheus/Grafana stack (Objective #2).

Step 5: Install Prometheus and Grafana

We will install the monitoring stack in a dedicated namespace.

# Add the required Helm repositories
helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
helm repo add grafana [https://grafana.github.io/helm-charts](https://grafana.github.io/helm-charts)
helm repo update

# Create the monitoring namespace
kubectl create namespace monitoring

# Install Prometheus using your custom values file (which now targets the 'nginx' service)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus/prometheus-values.yaml

# Install Grafana
helm install grafana grafana/grafana --namespace monitoring


Step 6: Access Grafana and Configure Dashboards

Access Grafana: Forward the Grafana service port to your local machine.

kubectl port-forward svc/grafana --namespace monitoring 3000:80
# Access Grafana at http://localhost:3000


Retrieve Admin Password:

kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo


Configure Prometheus Data Source: In Grafana, set up Prometheus as a data source using the URL http://prometheus:9090.

Create Custom Dashboard Panels: Use the following PromQL queries to meet the assignment requirements:

Metric Required

PromQL Query (Targeting Container Metrics)

Pod CPU Utilization

sum(rate(container_cpu_usage_seconds_total{namespace="default", container!="POD"}[5m])) by (pod)

Total Request Count (Nginx)

sum(rate(nginx_http_requests_total[5m])) by (instance)

Total 5xx Requests (Nginx)

sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (instance)

Clean Up

To remove all deployed components:

# Uninstall the WordPress application stack
helm uninstall my-release

# Uninstall the monitoring stack
helm uninstall prometheus --namespace monitoring
helm uninstall grafana --namespace monitoring

# Delete the namespace
kubectl delete namespace monitoring
