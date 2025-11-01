# 🚀 Kubernetes WordPress Deployment and Monitoring Stack

This repository provides a production-grade deployment solution for a WordPress application, featuring a Lua-enabled OpenResty Nginx proxy, deployed via Helm on a local Kubernetes cluster, integrated with a full Prometheus and Grafana monitoring stack.

## Objectives Completed

### 1\. WordPress Application Deployment

  * Stack: WordPress, MySQL, and OpenResty Nginx proxy.
  * Persistence: PersistentVolumeClaims (PVCs) for MySQL and WordPress data.
  * Deployment Method: Helm chart for unified deployment.

### 2\. Monitoring and Alerting Setup

  * Monitoring Stack: Prometheus (scraping) and Grafana (visualization).
  * Custom Metrics: Nginx is configured with Lua to expose traffic metrics for Prometheus scraping.

## Deployment Guide (PowerShell/Windows)

Run all commands from the inner project directory: `./k8s_wordpress-master/k8s_wordpress-master`

### Application Deployment

1.  Start Cluster:

<!-- end list -->

```bash
minikube start
minikube docker-env | Invoke-Expression
```

2.  Build and Load Docker Images:

<!-- end list -->

```bash
docker build -t my-project/wordpress-image:latest -f dockerfiles/wordpress.dockerfile .
docker build -t my-project/mysql-image:latest -f dockerfiles/mysql.dockerfile .
docker build -t my-project/my-nginx:latest -f dockerfiles/nginx/Dockerfile dockerfiles/nginx
```

3.  Install the Helm Chart:

<!-- end list -->

```bash
helm install my-release ./wordpress-chart
kubectl get pods -w
```

4.  Access the WordPress Application:

<!-- end list -->

```bash
minikube service my-release-nginx --url
```

*Paste the resulting URL into your browser to confirm the WordPress setup screen loads.*

### Monitoring Deployment

1.  Install Prometheus and Grafana:

<!-- end list -->

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
kubectl create namespace monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f monitoring/prometheus/prometheus-values.yaml
helm install grafana grafana/grafana --namespace monitoring
```

2.  Access and Verify Metrics:

<!-- end list -->

  * **Port-forward Grafana:** `kubectl port-forward svc/grafana --namespace monitoring 3000:80`
  * **Retrieve Password:** Use the following PowerShell command in a **new terminal**:

<!-- end list -->

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) } ; echo
```

  * **Validate Custom Metrics:** Log in to Grafana, select the **Prometheus** data source, and execute the following PromQL queries.

## Required Metrics (PromQL)

| Metric Required | PromQL Query |
| :--- | :--- |
| **Pod CPU Utilization** | `sum(rate(container_cpu_usage_seconds_total{namespace="default", container!="POD"}[5m])) by (pod)` |
| **Total Request Count (Nginx)** | `sum(rate(nginx_http_requests_total[5m])) by (instance)` |
| **Total 5xx Requests (Nginx)** | `sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (instance)` |

-----

## Clean Up

```bash
helm uninstall my-release
helm uninstall prometheus --namespace monitoring
helm uninstall grafana --namespace monitoring
kubectl delete namespace monitoring
```
