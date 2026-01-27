# Highly Available QR Generator Website

**Owner:** Filip Ermenkov

**Deployment Environment:** AWS (EKS)

This repository contains a full-stack, cloud-native QR Code generation platform. It serves as a comprehensive demonstration of modern DevOps engineering - transitioning from manual infrastructure management to a fully automated, scalable, and secure system. By leveraging **Terraform** for infrastructure, **Docker** for containerization, and **Kubernetes** for orchestration, this project achieves a "Zero-Trust" environment with a seamless **GitOps** workflow.

I have updated your Table of Contents to align perfectly with the headers used in the document. I also took the liberty of cleaning up the transition prose between the sections to make it read as a polished, professional `README.md`.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Overview](#2-architecture-overview)
3. [Getting Started](#3-getting-started)
4. [Infrastructure & Deployment](#4-infrastructure--deployment)
5. [Project Structure](#5-project-structure)
6. [Cost Analysis (2026)](#6-cost-analysis-2026)
7. [Contacts & License](#7-contacts--license)

---

## 1. Project Overview

The **QR Generator Ecosystem** is a cloud-native application designed to demonstrate the full lifecycle of modern DevOps engineering. At its core, the project transforms a simple utility - converting URLs into QR codes - into a highly available, scalable, and secure microservices platform.

### **The Challenge**

In a traditional environment, scaling an image generation service involves managing server state, handling erratic CPU spikes during encoding, and securing static assets. This project addresses these challenges by moving away from monolithic architecture toward a **decoupled, containerized approach** hosted on **Amazon EKS (Elastic Kubernetes Service)**.

### **Core Components**

* **Front-End (Next.js):** A responsive web interface optimized for performance using Next.js’s "Standalone" mode to minimize container footprint. It communicates with the backend via internal Kube-DNS.
* **API (FastAPI):** A high-performance, stateless Python backend handling QR encoding logic. It is architected for rapid horizontal scaling to manage CPU-intensive image generation.
* **Storage (AWS S3):** A centralized repository for all generated QR codes. The integration utilizes **EKS Pod Identity**, ensuring the application inherits secure, temporary permissions without hardcoded secrets.

### **Key DevOps Objectives**

* **Automation:** Eliminate manual configuration via **Infrastructure as Code (Terraform)**.
* **Security:** Implement a "Zero-Trust" networking model where compute resources reside in private subnets, accessible only through a managed Load Balancer.
* **Resilience:** Implement **Horizontal Pod Autoscaling (HPA)** targeting 70% utilization, allowing the backend to scale up to 12 replicas to handle high-burst traffic.
* **Efficiency:** Implement a **GitOps CI/CD pipeline** for an automated path from code push to production.

---

## 2. Architecture Overview

This project is built on a highly available, containerized infrastructure managed by **Terraform (IaC)** and orchestrated by **Kubernetes**. The architecture follows AWS best practices for security, scalability, and observability.

### Core Infrastructure Components

* **Compute (EKS):** A managed **Amazon EKS** cluster serves as the orchestration layer. It uses a managed node group with **t3.medium** instances across multiple Availability Zones for high availability.
* **Network (VPC):** A custom **VPC** with public/private subnets. Worker nodes reside in private subnets, while the **AWS Load Balancer Controller** manages an internet-facing ALB. A dedicated **S3 Gateway Endpoint** ensures internal traffic to storage stays within the AWS network.
* **Storage (S3):** An encrypted **S3 Bucket** stores and archives generated QR codes. It includes a lifecycle policy that automatically transitions old files to **Intelligent Tiering** after 30 days and expires them after 90 days.
* **Container Registry (ECR):** Two private **ECR repositories** (Frontend and Backend) store immutable Docker images, with an automated lifecycle policy to keep only the 5 most recent versions.

### Kubernetes Orchestration

The application is deployed within the `qr-generator` namespace, utilizing several K8s primitives for stability:

* **Workloads:** Both the **FastAPI Backend** and **Next.js Frontend** are deployed as `Deployments` with dual replicas for high availability, utilizing `liveness` and `readiness` probes for self-healing.
* **Service Discovery:** Internal communication is handled via `ClusterIP` services. The frontend communicates with the backend using the internal DNS: `http://qr-backend.qr-generator.svc.cluster.local:8000`.
* **Traffic Management:** An **Ingress** resource routes external traffic through the ALB. Pod readiness gates are enabled via namespace labels to ensure zero-downtime deployments during ALB registration.
* **Configuration:** Environment-specific settings like bucket names and regions are managed via a central `ConfigMap`.

### Security & Scaling

* **Least Privilege (IAM):** Implements **EKS Pod Identity**. The `backend-service-account` is mapped to a specific IAM role, allowing backend pods to securely access S3 without static credentials.
* **Auto-Scaling:** **Horizontal Pod Autoscalers (HPA)** are configured for both tiers:
    * **Backend:** Scales from 2 to 12 replicas based on 70% CPU/Memory utilization.
    * **Frontend:** Scales from 2 to 4 replicas based on 80% CPU/Memory utilization.


* **Metrics:** A custom-deployed **Metrics Server** in the `kube-system` namespace provides the necessary resource data for the HPAs to function.

### Observability

* **CloudWatch Observability:** Captures application logs and cluster metrics.
* **Container Insights:** Integrated to provide deep visibility into pod performance and EKS health.

---

## 3. Getting Started

You can run the **Best QR Generator Ever** either using Docker for a seamless experience or manually for development.

### Prerequisites

* **Docker & Docker Compose** (Recommended)
* **AWS Account:** An S3 bucket is required to store the generated images.
* **IAM Credentials:** Access key and Secret key with S3 permissions (for local use).

### Environment Configuration

Create a `.env` file in the root directory to configure both the backend and frontend:

```env
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=us-east-1
S3_BUCKET_NAME=best-qr-ever-generated-codes

# Frontend Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
```

---

### Option A: Running with Docker (Quick Start)

The project includes a `docker-compose.yml` that handles the networking, health checks, and build arguments automatically.

1. **Spin up the services:**
    ```bash
    docker-compose up --build
    ```


2. **Access the application:**
    * **Frontend:** [http://localhost:3000](https://www.google.com/search?q=http://localhost:3000)
    * **Backend API:** [http://localhost:8000](https://www.google.com/search?q=http://localhost:8000)
    * **API Health Check:** [http://localhost:8000/health](https://www.google.com/search?q=http://localhost:8000/health)



    > **Note:** The frontend container will wait for the backend to be `healthy` (passing its internal health check) before starting.

---

### Option B: Manual Development Setup

If you prefer to run the services without Docker for active debugging:

#### 1. Backend (FastAPI)

1. Navigate to the folder: `cd backend`

2. Create and activate a virtual environment:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    ```


3. Install dependencies: `pip install -r requirements.txt`

4. Run the server:
    ```bash
    uvicorn main:app --reload --port 8000
    ```



#### 2. Frontend (Next.js)

1. Navigate to the folder: `cd frontend`

2. Install dependencies: `npm install`

3. Run the development server:
    ```bash
    npm run dev
    ```

---

## 4. Infrastructure & Deployment

This project features a fully automated **GitOps-style CI/CD pipeline**. The infrastructure and application lifecycle are managed through GitHub Actions, allowing for a "one-click" deployment or destruction of the entire AWS environment.

### Automated CI/CD Workflow

The pipeline, defined in `.github/workflows/application-cicd.yml`, is triggered on any push to the `main` branch or via manual dispatch.

1. **Infrastructure Phase (Terraform):**
    * **Validation:** Runs `fmt` and `validate` to ensure IaC quality.
    * **Provisioning:** Provisions the VPC, EKS Cluster, ECR Repositories, and S3 Buckets.
    * **OIDC Security:** Uses AWS Federation (OIDC) to assume IAM roles without storing long-lived secrets in GitHub.


2. **Application Phase (Docker & K8s):**
    * **Build:** Packages the FastAPI and Next.js applications into Docker images.
    * **Registry:** Pushes versioned images (tagged with Git SHA) to Amazon ECR.
    * **Orchestration:** Updates the EKS cluster by applying Kubernetes manifests using `envsubst` to inject the latest image tags and security group IDs dynamically.



### Manual Deployment / Destruction

The workflow supports `workflow_dispatch`, enabling manual control through the GitHub Actions UI:

* **Deploy:** Select the **apply** action to provision the environment and deploy the app.
* **Teardown:** Select the **destroy** action to wipe the environment. The pipeline includes a specialized **Kubernetes Cleanup** step that deletes the `qr-generator` namespace and waits for AWS Load Balancers to drain before Terraform attempts to destroy the VPC, preventing dependency conflicts.

### Deployment Commands (CLI)

If you wish to run the deployment steps manually from your terminal:

#### 1. Infrastructure

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

#### 2. Kubernetes Application

After infrastructure is ready, update your local `kubeconfig`:

```bash
aws eks update-kubeconfig --region us-east-1 --name best-qr-ever
```

Then apply the manifests in order:

```bash
kubectl apply -f k8s/00-namespace.yml
kubectl apply -f k8s/config-env.yml
# ... apply remaining k8s/ directories
```

### Scaling & Monitoring

Once deployed, the cluster automatically manages health and scale:

* **Self-Healing:** Kubernetes `liveness` and `readiness` probes monitor container health.
* **Auto-Scaling:** The **Metrics Server** feeds data to the **HPA**, which will scale the backend up to 12 replicas during traffic spikes.
* **Ingress:** The **AWS Load Balancer Controller** automatically provisions a physical ALB and provides a DNS name to access the frontend.

---

## 5. Project Structure

The project is organized into a modular architecture that separates infrastructure, orchestration, and application logic. Below is a detailed map of the repository:

### Backend (`/backend`)

* **`main.py`**: The FastAPI application core. Handles QR generation logic, S3 client initialization, and AWS Pod Identity/IAM credential switching.
* **`requirements.txt`**: Lists Python dependencies (`fastapi`, `boto3`, `qrcode`, etc.).
* **`Dockerfile`**: Defines the Python environment and build steps for the API.
* **`.dockerignore`**: Optimizes the Docker build by excluding local virtual environments and logs.

### Frontend (`/frontend`)

* **`app/`**: Contains the Next.js App Router files (`page.tsx` for UI, `layout.tsx` for structure, and `globals.css` for styling).
* **`next.config.ts` & `tsconfig.json`**: Configuration files for Next.js features and TypeScript compiler settings.
* **`package.json`**: Defines Node.js dependencies and scripts (`dev`, `build`, `start`).
* **`Dockerfile`**: A multi-stage build file that compiles the Next.js production bundle.

### Terraform (`/terraform`)

* **`vpc.tf` & `security-groups.tf`**: Provisions the network foundation (Public/Private subnets, NAT Gateways) and firewall rules.
* **`eks.tf` & `ecr.tf`**: Manages the EKS Cluster, Node Groups, and the private container registries for image storage.
* **`iam.tf`**: Configures OIDC for GitHub Actions and EKS Pod Identity roles for S3 access.
* **`s3.tf`**: Defines the encrypted bucket and lifecycle policies for QR code storage.
* **`helm.tf`**: Deploys Kubernetes-native drivers (like the AWS Load Balancer Controller) via Helm providers.
* **`backend.tf`**: Configures the S3/DynamoDB remote state storage to prevent state corruption.
* **`provider.tf`, `variables.tf`, `outputs.tf`, `data.tf`**: Core Terraform configuration, input definitions, and cross-resource data fetching.
* **`cloudwatch.tf`**: Sets up log groups for cluster and application monitoring.

### Kubernetes (`/k8s`)

* **`00-namespace.yml`**: Creates the `qr-generator` isolated environment with pod-readiness gates for the ALB.
* **`01-rbac.yml` & `config-env.yml`**: Defines ServiceAccounts for Pod Identity and a ConfigMap for application environment variables.
* **`02-backend/`**: Deployment and ClusterIP Service manifests for the API.
* **`03-frontend/`**: Deployment, NodePort Service, and the Ingress resource that triggers the AWS ALB creation.
* **`04-monitoring/`**: Contains the Metrics Server deployment and Horizontal Pod Autoscaler (HPA) rules for dynamic scaling.

### GitHub Workflows (`/.github/workflows`)

* **`application-cicd.yml`**: The "brain" of the project's automation. It manages the two-phase lifecycle of Infrastructure (Terraform) and Application (Docker/Kubernetes) deployment.

---

To provide a precise **Cost Analysis (2026)**, I have nearly everything I need from your Terraform files, but two small details would make the numbers perfect:

1. **Expected Traffic/Usage:** How many QR codes do you expect to generate per month? (This affects S3 request costs and Data Transfer out).
2. **NAT Gateway Usage:** Does your Terraform code provision a NAT Gateway for the private subnets? (This is often the most expensive "hidden" cost for small EKS clusters).

Based on your current architecture (**EKS with t3.medium nodes**, **ALB**, **S3**, and **ECR**), here is a projected monthly cost analysis for 2026 in the `us-east-1` region.

---

## 6. Cost Analysis (2026)

The following table breaks down the estimated monthly operating costs for the production environment. This analysis assumes a standard "High Availability" configuration as defined in the Terraform files.

| Service | Component | Configuration Details | Est. Monthly Cost (USD) |
| --- | --- | --- | --- |
| **Amazon EKS** | Cluster Management | Standard EKS Control Plane fee | $73.00 |
| **Amazon EC2** | Worker Nodes | 2 x t3.medium Instances (On-Demand) | $60.74 |
| **Elastic Load Balancing** | Application Load Balancer | 1 ALB + 2 LCU (Avg. traffic) | $22.26 |
| **Amazon S3** | Storage & Requests | 50GB Storage + Standard API Requests | $2.50 |
| **Amazon ECR** | Image Storage | 2 Repositories (Retention: 5 versions) | $0.50 |
| **Networking** | NAT Gateway | 1 NAT Gateway (Idle + Data Processed) | $32.85 |
| **CloudWatch** | Observability | Logs, Metrics, and Alarms | $5.00 |
| **TOTAL** |  | **Estimated Monthly Total** | **~$196.85** |

### Cost Optimization Strategies

To reduce these costs for smaller projects, the following adjustments can be made:

* **Savings Plans:** Committing to 1-year compute usage can reduce EC2 costs by up to **30%**.
* **S3 Intelligent Tiering:** Already implemented in the code, this ensures that older QR codes automatically move to cheaper storage tiers.
* **Spot Instances:** Switching the EKS Managed Node Group to use **Spot Instances** for the worker nodes can reduce the EC2 portion of the bill by up to **70%**.

---

## 7. Contacts & license

**Owner:** Filip Ermenkov  -  [f.ermenkov@gmail.com](mailto:f.ermenkov@gmail.com)\
**License:** This project is licensed under the [MIT License](LICENSE)