# 🚀 Kubernetes WordPress Deployment and Monitoring Stack

This repository provides a production-grade deployment solution for a WordPress application, featuring a Lua-enabled OpenResty Nginx proxy, deployed via Helm on a local Kubernetes cluster (Minikube/Docker Desktop), integrated with a full Prometheus and Grafana monitoring stack.

## 🎯 Objectives Completed

### 1. Run a Production Grade Wordpress app on Kubernetes
* **Application Stack:** WordPress (Apache), MySQL, and OpenResty Nginx proxy.
* **Configuration:** Nginx utilizes Lua scripting (`init_by_lua_block` and `log_by_lua_block`) to expose Prometheus metrics.
* **Deployment Method:** Application components are packaged and deployed using a single Helm chart (`wordpress-chart/`).
* **Persistence:** PersistentVolumeClaims (PVCs) are defined for both MySQL and WordPress data.

### 2. Setup Monitoring and Alerting for Wordpress App
* **Monitoring Stack:** Prometheus (for scraping) and Grafana (for visualization) are deployed using public Helm charts.
* **Custom Metrics:** Prometheus is configured to scrape the Nginx Service via annotations, targeting the `/metrics` endpoint exposed by Lua.

---

## 🛠️ Prerequisites

Ensure the following tools are installed: **Minikube** (or Docker Desktop with K8s), **kubectl**, **helm**, and **Docker**.

## 💻 Deployment Guide (PowerShell/Windows)

Run all commands from the inner project directory: `./k8s_wordpress-master/k8s_wordpress-master`

### Phase 1: Application Deployment (Objective #1)

1.  **Start Cluster and Configure Docker Environment:**
    ```bash
    minikube start
    minikube docker-env | Invoke-Expression
    ```

2.  **Build and Load Docker Images Locally:**
    *(Note: Using custom tags defined in `values.yaml`)*
    ```bash
    docker build -t my-project/wordpress-image:latest -f dockerfiles/wordpress.dockerfile .
    docker build -t my-project/mysql-image:latest -f dockerfiles/mysql.dockerfile .
    docker build --no-cache -t my-project/my-nginx:latest -f dockerfiles/nginx/Dockerfile dockerfiles/nginx
    ```

3.  **Install the WordPress Helm Chart:**
    ```bash
    helm install my-release ./wordpress-chart
    kubectl get pods -w # Wait for all 1/1 Running
    ```

4.  **Access the WordPress Application:**
    ```bash
    minikube service my-release-nginx --url
    ```
    *Paste the resulting URL into your browser to confirm the WordPress setup screen loads.*

### Phase 2: Monitoring Deployment and Verification (Objective #2)

1.  **Install Prometheus and Grafana:**
    ```bash
    helm repo add prometheus-community [https://prometheus-community.github.io/helm-charts](https://prometheus-community.github.io/helm-charts)
    helm repo add grafana [https://grafana.github.io/helm-charts](https://grafana.github.io/helm-charts)
    helm repo update
    kubectl create namespace monitoring

    # Install Prometheus (uses custom scrape config)
    helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f monitoring/prometheus/prometheus-values.yaml

    # Install Grafana
    helm install grafana grafana/grafana --namespace monitoring
    ```

2.  **Access Grafana and Verify Metrics:**
    * **Port-forward Grafana:** `kubectl port-forward svc/grafana --namespace monitoring 3000:80`
    * **Retrieve Password:** Use the following PowerShell command in a **new terminal**:
        ```bash
        kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } ; echo
        ```
    * **Validate Custom Metrics:** Log in to Grafana (`http://localhost:3000`), select the **Prometheus** data source, and execute the following PromQL queries.

## 📊 Required Metrics Documentation

| Metric Required | PromQL Query |
| :--- | :--- |
| **Pod CPU Utilization** | `sum(rate(container_cpu_usage_seconds_total{namespace="default", container!="POD"}[5m])) by (pod)` |
| **Total Request Count (Nginx)** | `sum(rate(nginx_http_requests_total[5m])) by (instance)` |
| **Total 5xx Requests (Nginx)** | `sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (instance)` |

---

## 🗑️ Step 2: Clean Up Your Environment

Run these commands in your terminal to remove all deployed components from your local Kubernetes cluster:

```bash
# Uninstall application release
helm uninstall my-release

# Uninstall monitoring stack
helm uninstall prometheus --namespace monitoring
helm uninstall grafana --namespace monitoring
kubectl delete namespace monitoring
