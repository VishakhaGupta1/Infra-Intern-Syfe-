# Kubernetes WordPress Deployment (Local Environment)

This guide provides instructions for deploying a production-grade WordPress application, including MySQL and a Lua-enabled OpenResty Nginx proxy, on a **local Kubernetes cluster** (like Minikube or Docker Desktop).

## **Project Structure Overview**

The repository structure is organized as follows:

- **DockerFiles/**
  - `dockerfile.mysql`
  - `dockerfile.wordpress`
  - **nginx/**
    - `Dockerfile`
    - `nginx.conf`
- **monitoring/**
  - **prometheus/**
    - `prometheus-values.yaml`
- **wordpress-chart/** (Helm Chart)
  - `Chart.yaml`
  - `values.yaml`
  - **templates/**
    - `mysql-deployment.yaml`
    - `nginx-deployment.yaml`
    - `wordpress-deployment.yaml`

---

## **Prerequisites**

Ensure the following tools are installed and configured on your local machine:

- **Local Kubernetes Cluster:** Install and start either Minikube or Docker Desktop (with Kubernetes enabled).
- **kubectl:** Kubernetes command-line tool.
- **helm:** Kubernetes package manager.
- **Docker:** For building container images.
- **Git:** For version control.

---

## **Deployment Guide: WordPress Application (Objective #1)**

### **Step 1: Start Kubernetes and Configure Docker Environment**

Start your local cluster and ensure your Docker environment is connected to it so Kubernetes can access the images you build.

```bash
# 1. Start Minikube (or verify Docker Desktop Kubernetes is running)
minikube start

# 2. Point your local Docker CLI to Minikube's Docker daemon
eval $(minikube docker-env)
```

---

### **Step 2: Build and Load Docker Images Locally**

Build the container images and tag them using the names specified in `wordpress-chart/values.yaml`.

Run these commands from the root directory of the project.

```bash
# 1. Build WordPress Image
sudo docker build -t yashingole1000/wordpress-image:latest -f dockerfiles/wordpress.dockerfile .

# 2. Build MySQL Image
sudo docker build -t yashingole1000/mysql-image:latest -f dockerfiles/mysql.dockerfile .

# 3. Build Nginx Image (OpenResty with Lua modules)
sudo docker build -t yashingole1000/my-nginx:latest -f dockerfiles/nginx/Dockerfile dockerfiles/nginx
```

---

### **Step 3: Install the WordPress Helm Chart**

This installation deploys the database, application, and proxy service using the corrected local configurations (NodePort service type, default storage).

```bash
# Install the chart using the release name 'my-release'
helm install my-release ./wordpress-chart

# Verify that all components are running
kubectl get pods -w
```

---

### **Step 4: Access the WordPress Application**

The Nginx Service is exposed via NodePort. Use the minikube service command to get the external URL.

```bash
# Get the external URL for the Nginx proxy (which forwards to WordPress)
minikube service my-release-nginx --url
```

Paste the resulting URL into your browser to complete the WordPress setup.

---

## **Deployment Guide: Monitoring and Alerting (Objective #2)**

### **Step 5: Install Prometheus and Grafana**

We will deploy the monitoring stack, ensuring Prometheus uses the fixed configuration to scrape Nginx metrics.

```bash
# Add Helm repositories and create namespace
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace monitoring

# Install Prometheus using the custom values file (prometheus-values.yaml)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f monitoring/prometheus/prometheus-values.yaml

# Install Grafana
helm install grafana grafana/grafana --namespace monitoring
```

---

### **Step 6: Access Grafana and Configure Dashboards**

- **Access Grafana:** Forward the Grafana service port to your local machine (http://localhost:3000).

```bash
kubectl port-forward svc/grafana --namespace monitoring 3000:80
```

- **Retrieve Admin Password:**

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

- **Create Custom Dashboard Panels:**  
  Once logged in, configure Prometheus as a data source, and create panels using the following PromQL queries to meet the assignment requirements:

| Metric Required       | PromQL Query                                                                                   |
|----------------------|-----------------------------------------------------------------------------------------------|
| Pod CPU Utilization  | `sum(rate(container_cpu_usage_seconds_total{namespace="default", container!="POD"}[5m])) by (pod)` |
| Total Request Count (Nginx) | `sum(rate(nginx_http_requests_total[5m])) by (instance)`                                |
| Total 5xx Requests (Nginx)  | `sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (instance)`                 |

---

## **Clean Up**

To remove all deployed components from your cluster:

```bash
helm uninstall my-release
helm uninstall prometheus --namespace monitoring
helm uninstall grafana --namespace monitoring
kubectl delete namespace monitoring
```
