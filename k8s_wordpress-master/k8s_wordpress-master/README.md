## EKS WordPress Deployment

### Project Structure Overview

```
├── DockerFiles
│   ├── dockerfile.mysql
│   ├── dockerfile.wordpress
│   └── nginx
│       ├── Dockerfile
│       ├── nginx.conf
├── monitoring
│   ├── prometheus
│   │   ├── prometheus-values.yaml
└── wordpress-chart
    ├── Chart.yaml
    ├── templates
    │   ├── mysql-deployment.yaml
    │   ├── nginx-deployment.yaml
    │   ├── pvc.yaml
    │   ├── wordpress-deployment.yaml
    └── values.yaml
```

### Prerequisites

Ensure you have the following installed and configured:

1. **AWS CLI**: For managing AWS resources.
2. **kubectl**: For interacting with Kubernetes clusters.
3. **helm**: For managing Kubernetes applications.
4. **Docker**: For building and pushing container images.
5. **Git**: For version control and managing repositories.

### Step-by-Step Deployment Guide

#### Step 1: Set Up Amazon EKS Cluster

1. **Create an EKS Cluster:**

   ```sh
   eksctl create cluster --name my-wordpress-cluster --region us-west-2 --nodegroup-name standard-workers --node-type t3.medium --nodes 3 --nodes-min 1 --nodes-max 4 --managed
   ```

2. **Configure `kubectl` to Use Your EKS Cluster:**

   ```sh
   aws eks --region us-west-2 update-kubeconfig --name my-wordpress-cluster
   ```

#### Step 2: Set Up EFS CSI Driver

1. **Create IAM Policy for EFS CSI Driver:**

   ```sh
   aws iam create-policy --policy-name EKS_EFS_CSI_Driver_Policy-2 --policy-document file://newpolicy.json
   ```

2. **Create IAM Service Account and Attach Policy:**

   ```sh
   eksctl create iamserviceaccount --cluster my-wordpress-cluster --namespace kube-system --name efs-csi-controller-sa --attach-policy-arn arn:aws:iam::409943371208:policy/EKS_EFS_CSI_Driver_Policy-2 --approve --region us-east-2 --override-existing-serviceaccounts
   ```

3. **Ensure EFS is in the Same VPC as the EKS Cluster.**

4. **Add Helm Repo for EFS CSI Driver:**

   ```sh
   helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
   ```

5. **Update Helm Repo:**

   ```sh
   helm repo update aws-efs-csi-driver
   ```

6. **Install EFS CSI Driver Using Helm:**

   ```sh
   helm upgrade --install aws-efs-csi-driver --namespace kube-system aws-efs-csi-driver/aws-efs-csi-driver
   ```

#### Step 3: Create PersistentVolumeClaims and PersistentVolumes

1. **Create `pvc.yaml`:**

   This file includes configurations for PersistentVolumes (PV) and PersistentVolumeClaims (PVC).

#### Step 4: Create Dockerfiles

1. **Dockerfiles for Each Component:**

   - **`Dockerfile.wordpress`**: For WordPress.
   - **`Dockerfile.mysql`**: For MySQL.
   - **`Dockerfile.nginx`**: For Nginx.

   **Configuration for OpenResty Nginx Dockerfile:**

   ```Dockerfile
   FROM openresty/openresty:1.19.9.1
   RUN ./configure --prefix=/opt/openresty \
       --with-pcre-jit \
       --with-ipv6 \
       --without-http_redis2_module \
       --with-http_iconv_module \
       --with-http_postgres_module \
       -j8
   COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
   ```

2. **Create `nginx.conf`:**

   Define the Nginx configuration to set up a proxy pass from Nginx to WordPress.

#### Step 5: Build and Push Docker Images

1. **Build Docker Images:**

   ```sh
   sudo docker build -t yashingole1000/wordpress:v1 -f DockerFiles/dockerfile.wordpress .
   sudo docker build -t yashingole1000/mysql:v1 -f DockerFiles/dockerfile.mysql .
   sudo docker build -t yashingole1000/nginx:v1 -f DockerFiles/nginx/Dockerfile .
   ```

2. **Push Docker Images to Docker Hub:**

   ```sh
   sudo docker push yashingole1000/wordpress:v1
   sudo docker push yashingole1000/mysql:v1
   sudo docker push yashingole1000/nginx:v1
   ```

#### Step 6: Configure Helm Chart

1. **Create a Helm Chart:**

   ```sh
   helm create wordpress-chart
   ```

2. **Edit `wordpress-chart/values.yaml`:**

   Set values for the Helm chart, such as image repository, tag, and resource requests/limits.

3. **Create `pvc.yaml` Inside the Helm Chart Directory:**

   This file includes configurations for PersistentVolumes and PersistentVolumeClaims.

4. **Create Helm Chart Templates:**

   Define Kubernetes resources in YAML files within `wordpress-chart/templates/`. Example files include:

   - **`mysql-deployment.yaml`**: Deployment configuration for MySQL.
   - **`wordpress-deployment.yaml`**: Deployment configuration for WordPress.
   - **`nginx-deployment.yaml`**: Deployment configuration for Nginx.
   - **`mysql-service.yaml`**: Service configuration for MySQL.
   - **`nginx-service.yaml`**: Service configuration for Nginx.
   - **`wordpress-service.yaml`**: Service configuration for WordPress.
   - **`pvc.yaml`**: Configuration for PersistentVolumes and PersistentVolumeClaims.

   All relevant code for these files is included in the repository.

5. **Install the Helm Chart:**

   ```sh
   helm install my-release ./wordpress-chart
   ```

6. **Clean Up Helm Release (if needed):**

   ```sh
   helm uninstall my-release
   ```
   ![kubectl get pods](https://github.com/user-attachments/assets/210b28f3-c24c-4dab-993a-83d4a98f41d7)

   ![OpenResty using load balancer DNS](https://github.com/user-attachments/assets/1c497b32-87f3-44fe-a453-b43b18efb15b)
### Monitoring Setup

#### Add Prometheus and Grafana Repositories to Helm

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
```

#### Create a New Namespace for Monitoring

```sh
kubectl create namespace monitoring
```

#### Install Prometheus

```sh
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring
```

#### Access Prometheus GUI

```sh
kubectl port-forward svc/prometheus-kube-prometheus-prometheus --namespace monitoring 9090:9090
```

- **Check for Targets**: Ensure that Nginx and WordPress appear as targets in Prometheus.

#### Install Grafana

```sh
helm install grafana grafana/grafana --namespace monitoring
kubectl port-forward svc/grafana 3000:3000
```

- **Access Grafana**: [http://localhost:3000](http://localhost:3000)

![Screenshot 2024-07-25 144131](https://github.com/user-attachments/assets/d76d45e1-4e12-4f5f-887d-aafb87646086)

#### Configure Prometheus Data Source in Grafana

1. **Set Prometheus as the Data Source:**
   - Go to Grafana -> Configuration -> Data Sources.
   - Add Prometheus and configure the URL as `http://prometheus:9090`.

2. **Create Grafana Dashboards:**

   a. **Create a New Dashboard:**
      - Go to Grafana -> Dashboards -> New Dashboard.
      - Add a new panel for each of the following queries.

   b. **Run PromQL Queries in Grafana Panels:**

      - **Monitor Pod CPU Utilization:**

        ```promql
        sum(rate(container_cpu_usage_seconds_total{namespace="<your-namespace>", container!="POD"}[5m])) by (pod)
        ```

      - **Total Request Count for Nginx:**

        ```promql
        sum(rate(nginx_http_requests_total[5m])) by (instance)
        ```

      - **Total 5xx Requests for Nginx:**

        ```promql
        sum(rate(nginx_http_requests_total{status=~"5.."}[5m])) by (instance)
        ```

   c. **Save and Customize Dashboards:**
      - Customize the appearance and layout of your dashboard to meet your monitoring needs.
      - Save your dashboard for future reference.

### Conclusion

- **Code and Configurations**: All relevant files and configurations are available in the repository.
- **Documentation**: Detailed README notes are provided for deploying and testing the setup.
- **Screenshots**: Visual documentation is available in the `Screenshots` directory for reference.

![Screenshot 2024-07-25 194046](https://github.com/user-attachments/assets/3b5d08fd-7a9d-47cd-a57e-e5e0b4d5365a)
