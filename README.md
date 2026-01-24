# Highly Available QR Generator Website

**Owner:** Filip Ermenkov

**Deployment Environment:** AWS (EKS)

This repository contains a full-stack, cloud-native QR Code generation platform. It serves as a comprehensive demonstration of modern DevOps engineering—transitioning from manual infrastructure management to a fully automated, scalable, and secure system. By leveraging **Terraform** for infrastructure, **Docker** for containerization, and **Kubernetes** for orchestration, this project achieves a "Zero-Trust" environment with a seamless **GitOps** workflow.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Design](#architecture-design)
3. [Repository Structure](#repository-structure)
4. [Infrastructure as Code (Terraform)](#infrastructure-as-code-terraform)
5. [Kubernetes Orchestration](#kubernetes-orchestration)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Observability & Monitoring](#observability--monitoring)
8. [Cost Analysis (2026)](#cost-analysis-2026)

---

## Project Overview

The **QR Generator Ecosystem** is a cloud-native application designed to demonstrate the full lifecycle of modern DevOps engineering. At its core, the project transforms a simple utility—converting URLs into QR codes—into a highly available, scalable, and secure microservices platform.

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

## Architecture Design

The architecture is built on the principle of **separation of concerns**, ensuring networking, compute, and storage layers are decoupled for maximum security.

### **A. Network Layer (AWS VPC & Security)**

The foundation is a custom VPC enforcing a strict "Private-First" policy:

* **Public Subnets:** House the **Internet Gateway** and the **Network Load Balancer (NLB)**. This is the only entry point from the public internet.
* **Private Subnets:** All EKS Worker Nodes reside here with no public IP addresses, protected from direct external access.
* **Micro-Segmentation:** Worker nodes utilize a "Defense-in-Depth" approach. The Node Security Group restricts traffic to high-order ports (`1025-65535`) exclusively from the Load Balancer.
* **Connectivity:** A centralized **NAT Gateway** provides secure outbound access, while a **Gateway VPC Endpoint** for S3 keeps storage traffic within the AWS internal network to eliminate data transfer costs.

### **B. Compute Layer (Amazon EKS)**

The cluster uses modern EKS features for security and reduced operational overhead:

* **Amazon Linux 2023 (AL2023):** Managed Node Groups use the latest AL2023-optimized AMIs for a minimal attack surface.
* **Access Management API:** Utilizes `authentication_mode = "API"`, replacing legacy `aws-auth` ConfigMaps with auditable IAM identity management.
* **EKS Pod Identity:** Simplifies how pods assume IAM roles using the **Pod Identity Agent** add-on.
* **Managed Add-ons & Tooling:**
    * **AWS Load Balancer Controller:** (Installed via Helm) Authenticated via Pod Identity to dynamically manage NLB.
    * **Metrics Server:** Deployed to `kube-system` to enable resource-based autoscaling (HPA).
    * **EBS CSI Driver:** Enables persistent block storage for stateful requirements.
    * **CloudWatch Observability:** Uses a dedicated IAM role and Pod Identity to stream logs and metrics to CloudWatch.



### **C. Storage & Artifact Management**

* **Secure S3 Storage:** * **Encryption:** All objects encrypted at rest via **AES256**.
    * **Encrypted Transit:** Bucket policy enforces **SSL-only requests** (`aws:SecureTransport: true`).
    * **Lifecycle Logic:** Objects move to **Intelligent-Tiering** after 30 days and expire after 90 days to optimize costs.


* **ECR Artifact Integrity:** * **Vulnerability Scanning:** Images are **scanned on push** for security flaws.
    * **Tag Immutability:** Prevents overwriting image tags to ensure deployment consistency.
    * **Cleanup:** Lifecycle policies retain only the last 5 images per repository.



### **D. Application Logic & Data Flow**

1. **Request:** User submits a URL via the Next.js Frontend.
2. **API Call:** Frontend sends a request to the FastAPI Backend via the internal Service DNS (`qr-backend.qr-generator.svc.cluster.local`).
3. **Generation:** Backend generates a QR code and utilizes **EKS Pod Identity** to securely upload the binary to **S3**.
4. **Presigned URL:** The API generates a temporary, time-limited **Presigned URL**, keeping the S3 bucket private.
5. **Response:** The Frontend displays the QR code via the secure link, ensuring the storage layer remains hidden.

## Repository Structure

The project is organized to maintain a strict separation between infrastructure, application logic, and orchestration manifests. This structure supports a **modular DevOps workflow**, allowing teams to update infrastructure without disrupting application code.

```text
.
├── .github/
│   └── workflows/          # CI/CD pipelines (GitHub Actions)
├── k8s/                    # Kubernetes Manifests
│   ├── 00-namespace.yml    # Logical isolation (qr-generator)
│   ├── 01-rbac.yml         # ServiceAccount for Pod Identity
│   ├── 02-backend/         # FastAPI Deployment and ClusterIP Service
│   ├── 03-frontend/        # Next.js Deployment and NLB LoadBalancer Service
│   ├── 04-monitoring/      # HPA and Metrics Server configurations
│   └── config-env.yml      # ConfigMap (S3 bucket and Region)
├── terraform/              # Infrastructure as Code (AWS)
│   ├── backend.tf          # Remote state (S3/DynamoDB)
│   ├── cloudwatch.tf       # EKS and App log groups
│   ├── data.tf             # External policies and certificates
│   ├── ecr.tf              # Immutable container registries
│   ├── eks.tf              # Cluster, Node Groups, and Add-ons
│   ├── helm.tf             # NLB Controller via Helm
│   ├── iam.tf              # Pod Identity and GitHub OIDC roles
│   ├── outputs.tf          # Critical resource identifiers
│   ├── provider.tf         # AWS, Helm, and Kubernetes providers
│   ├── s3.tf               # Secure storage for QR codes
│   ├── security-groups.tf  # Firewalls and micro-segmentation
│   ├── variables.tf        # Parameterized inputs
│   └── vpc.tf              # Networking (Subnets, NAT, S3 Endpoint)
├── frontend/               # Next.js (Standalone mode)
└── backend/                # FastAPI (QR Generation logic)
└── README.md               # Documentation and Architectural Guide

```

### **Core Directory Highlights**

* **`terraform/`**: Defines the foundational cloud environment. It automates the creation of the VPC, the EKS cluster with AL2023 nodes, and the necessary IAM roles for **EKS Pod Identity**.
* **`k8s/`**: Orchestrates the application using a numerical sequence. The **Frontend Service** is configured as a `LoadBalancer` type, using AWS-specific annotations to provision an **Internet-facing NLB**. The **Monitoring** folder includes a full `metrics-server` deployment to support the defined `HorizontalPodAutoscaler` resources.
* **`backend/` and `frontend/**`: The backend utilizes the `backend-service-account` to assume IAM permissions for S3, while the frontend is configured to point to the backend's internal ClusterIP DNS: `http://qr-backend.qr-generator.svc.cluster.local:8000`.

---

## Infrastructure as Code (Terraform)

The infrastructure is managed entirely through Terraform, following a **modular and stateful approach**. By codifying the AWS environment, we ensure that the platform is reproducible, auditable, and protected against configuration drift.

### **A. Backend & State Management**

To support team collaboration and prevent concurrent modifications, the project utilizes a **Remote Backend** (defined in `backend.tf`):

* **S3 Bucket:** `best-qr-ever-terraform-state` stores the `terraform.tfstate` file as the single source of truth.
* **DynamoDB Table:** `terraform-state-lock` implements **State Locking**, preventing race conditions during concurrent `terraform apply` runs.
* **Encryption:** The state file is secured with **AES256** server-side encryption.

### **B. Provisioning Logic**

The `terraform/` directory is modularized to maintain clarity and separation of concerns:

| File | Responsibility | Key Features |
| --- | --- | --- |
| `vpc.tf` | **Networking** | 2-AZ VPC with NAT Gateway and an **S3 Gateway Endpoint** to eliminate data transfer costs. |
| `eks.tf` | **Compute** | Managed Cluster using **AL2023** nodes, **EBS CSI Driver**, and the **Access Management API**. |
| `iam.tf` | **Identity** | Configures **EKS Pod Identity** associations for S3 access, LB controller, and Observability. |
| `ecr.tf` | **Registry** | Dual repositories with **AES256 encryption**, **Scan-on-Push**, and **Tag Immutability**. |
| `s3.tf` | **Storage** | Private bucket with **SSL-only enforcement**, Versioning, and **Intelligent-Tiering**. |
| `helm.tf` | **Add-ons** | Deploys the **AWS Load Balancer Controller** via Helm, integrated with Pod Identity. |

### **C. Security & Networking Blueprint**

The infrastructure adheres to the **Principle of Least Privilege (PoLP)**:

* **Zero-Trust Identity:** Traditional IAM users are replaced by **OIDC-federated roles** for GitHub Actions and **EKS Pod Identity** for granular pod-level permissions.
* **Micro-Segmentation:** `security-groups.tf` restricts worker node ingress to high-order ports (`1025-65535`) exclusively from the load balancer tier.
* **Encrypted Transit:** The S3 bucket policy (defined in `s3.tf`) explicitly denies any non-HTTPS traffic using the `aws:SecureTransport` condition.

### **D. Idempotency & Validation**

The configuration is designed to be **idempotent**, ensuring consistent state across environments:

* **Variable Validation:** `variables.tf` enforces a regex constraint on `project_name` to ensure only lowercase letters, numbers, and hyphens are used.
* **Automated Cleanup:** ECR lifecycle policies retain only the **last 5 images**, and S3 lifecycle rules expire objects after 90 days to control long-term costs.

---

## **Kubernetes Orchestration**

The application is deployed on **Amazon EKS (v1.31)** using a declarative microservices architecture. The orchestration layer ensures the QR Generator is highly available and scales dynamically based on real-time demand.

### **A. Workload Architecture**

The system is organized within the `qr-generator` namespace, separating concerns into two core deployments:

* **Frontend (NextJS):** Manages the user interface with a replica min count of 2. It communicates with the backend via internal cluster DNS.
* **Backend (FastAPI):** Processes QR generation logic. It uses a dedicated **ServiceAccount** (`backend-service-account`) coupled with **EKS Pod Identity** to securely access S3 buckets without managing long-lived AWS credentials.

### **B. Networking & Traffic Flow**

* **External Access (NLB):** The frontend is exposed to the internet via an **AWS Network Load Balancer (NLB)**, configured through the AWS Load Balancer Controller. This provides a high-performance entry point at Layer 4.
* **Service Discovery:** Internal communication is handled by `ClusterIP` services. The frontend reaches the backend using the internal URI: `http://qr-backend.qr-generator.svc.cluster.local:8000`.
* **Health Monitoring:** Both services implement `liveness` and `readiness` probes. The backend specifically monitors a `/health` endpoint to ensure the API is fully initialized before receiving traffic.

### **C. Scaling & Resource Governance**

To maintain stability and cost-efficiency, the cluster utilizes:

* **Horizontal Pod Autoscaler (HPA):** Both tiers scale automatically. The backend is configured to scale up to **12 replicas** if CPU or Memory utilization exceeds **70%**, ensuring responsiveness during peak generation requests.
* **Resource Constraints:** Every container specifies exact **CPU/Memory requests and limits** (e.g., 250m CPU request / 500m limit). This allows the Kubernetes scheduler to place pods intelligently and prevents any single container from exhausting node resources.

### **D. Configuration Management**

* **Environment Decoupling:** Global settings like `S3_BUCKET_NAME` and `AWS_REGION` are managed via a centralized **ConfigMap** (`qr-config`). This allows for configuration changes without rebuilding container images.

---

## **CI/CD Pipeline**

The application employs a unified **GitHub Actions** workflow (`application-cicd.yml`) to manage the complete lifecycle of both infrastructure and application code. The pipeline is designed around the "Build Once, Deploy Anywhere" principle, using the Git SHA as a unique immutable identifier for container images.

### **A. Workflow Architecture**

The pipeline is split into two primary jobs, ensuring that infrastructure requirements are satisfied before any application code is deployed.

| Job | Responsibility | Triggers |
| --- | --- | --- |
| **Infrastructure** | Manages EKS, ECR, and IAM via Terraform. Handles `plan` on PRs and `apply` on merges. | Pushes to `main`, PRs, or Manual Dispatch. |
| **App Deployment** | Builds Docker images, pushes to ECR, and updates K8s manifests. | Successful completion or skipped status of Infrastructure job. |

### **B. Infrastructure Lifecycle (Terraform Job)**

This job automates the management of AWS resources within the `terraform/` directory:

* **Validation & Security:** Every push triggers `terraform fmt` and `terraform validate`. It uses **OIDC-based authentication** to assume the `GitHub_Actions_Resources_Deployment` role, eliminating the need for static AWS keys.
* **Plan Transparency:** On Pull Requests, the plan output is automatically commented back to the PR using `actions/github-script`, allowing for immediate peer review of infrastructure changes.
* **Controlled Destruction:** A manual `workflow_dispatch` trigger allows for an environment teardown. It includes a **Pre-Destroy Cleanup** step that manually deletes the Kubernetes namespace to ensure AWS Load Balancers and Network Interfaces are drained before Terraform attempts to destroy the VPC and Cluster.

### **C. Application Delivery (Deploy Job)**

This job handles the containerization and orchestration, running only if a `destroy` action was not requested:

* **Optimized Docker Builds:** Builds and pushes images for the `frontend` and `backend` to Amazon ECR. The frontend build specifically injects the internal API URL (`http://qr-backend...`) as a **Build Argument** to bake the service endpoint into the NextJS static assets.
* **Dynamic Manifest Templating:** Uses `envsubst` to inject the unique `${BACKEND_IMAGE}` and `${FRONTEND_IMAGE}` (tagged with the Git SHA) into the Kubernetes deployment files on the fly.
* **Ordered Deployment & Verification:** Applies manifests in a specific dependency order (Namespace -> ConfigMap -> RBAC -> Workloads -> HPA). The pipeline concludes with a `kubectl rollout status` check, which will fail the build if the new pods do not reach a "Healthy" state within 120 seconds.

---

## **Observability & Monitoring**

The project implements a cloud-native observability stack that leverages native AWS integrations and Kubernetes standards to ensure high availability and deep performance insights.

### **A. Real-Time Resource Metrics & Scaling**

While the infrastructure provides the foundation, the cluster uses real-time signals to maintain application performance:

* **Metrics Server:** Deployed via the `k8s/04-monitoring/metrics-server.yml` manifest. It aggregates CPU and memory data from nodes and pods, exposing the `metrics.k8s.io` API. This enables the use of `kubectl top` for live performance auditing.
* **Dual Horizontal Pod Autoscalers (HPA):** As defined in `hpa.yml`, the cluster manages two distinct scaling policies:
    * **Backend:** Scales between **2 and 12 replicas** targeting **70%** CPU/Memory utilization.
    * **Frontend:** Scales between **2 and 4 replicas** targeting **80%** CPU/Memory utilization.



### **B. CloudWatch Observability Integration**

The infrastructure uses the **Amazon CloudWatch Observability EKS Add-on** (managed in `eks.tf`) to bridge the gap between cluster events and AWS monitoring tools.

| Feature | Resource / Detail | Purpose |
| --- | --- | --- |
| **Control Plane Logs** | `enabled_cluster_log_types` in `eks.tf` | Captures API, Audit, and Scheduler logs in the `/aws/eks/.../cluster` group. |
| **Application Logs** | `aws_cloudwatch_log_group.app_logs` | Aggregates all logs from the `qr-generator` namespace for long-term analysis. |
| **Container Insights** | Managed via EKS Add-on | Provides automated dashboards for Pod-level CPU, Memory, and Network I/O. |
| **Pod Identity** | `cloudwatch-obs` association | Grants the `CloudWatchAgentServerPolicy` to the agent using the modern Pod Identity agent. |

### **C. Health Checks & Self-Healing**

The system is configured to detect and recover from failures automatically using probes defined in the deployment manifests:

* **Backend Probes:** Uses the `/health` endpoint on port 8000 with a 15s initial delay to ensure the API is fully booted before accepting traffic.
* **Frontend Probes:** Monitors the root path `/` on port 3000 to ensure the web server is responsive.
* **Efficient Log Retention:** To manage costs while maintaining visibility, both cluster and application log groups are configured with a **7-day retention policy** (defined in `cloudwatch.tf`).
* **EKS Health Monitoring:** CloudWatch monitors the EKS control plane and node group status, providing a historical record of cluster availability and resource saturation.

---

## **Cost Analysis (2026)**

This section provides a projected monthly budget for the platform based on **2026 AWS Pricing** in the `us-east-1` region. The analysis assumes a steady-state production environment using the resources defined in the provided Terraform configuration.

### **A. Monthly Infrastructure Breakdown**

| Service Component | Estimated Usage | Monthly Cost (USD) |
| --- | --- | --- |
| **EKS Control Plane** | 1 Cluster (Standard Support) | **$73.00** |
| **EC2 Worker Nodes** | 2x `t3.medium` (Defined in `eks.tf`) | **$61.00** |
| **NAT Gateway** | 1 Gateway (Defined in `vpc.tf`) | **$32.85** |
| **Public IPv4 Addresses** | 2 IPs (NAT Gateway + ALB) | **$7.30** |
| **Application Load Balancer** | 1 ALB (via Helm Controller) + LCU | **$22.50** |
| **S3 & ECR Storage** | 100GB S3 + 5GB ECR (7-day retention) | **$4.00** |
| **CloudWatch Logs** | Ingestion + 7-day retention (`cloudwatch.tf`) | **$6.50** |
| **Total Estimated Monthly Cost** | — | **~$207.15** |

---

### **B. Key Cost Drivers & Assumptions**

1. **The "Control Plane" Tax:** Amazon EKS carries a fixed cost of **$0.10/hour**. This is unavoidable for managed Kubernetes and represents the largest single cost for a small-scale cluster.
2. **Managed NAT Gateways:** To allow nodes in private subnets to pull images and updates, one NAT Gateway is provisioned in `vpc.tf`. This incurs a flat hourly rate plus data processing fees.
3. **Public IPv4 Pricing:** As of 2024, AWS charges **$0.005/hour** for every public IPv4 address. The architecture uses two: one for the NAT Gateway and one for the internet-facing Load Balancer.
4. **Intelligent Storage:** By using `INTELLIGENT_TIERING` in `s3.tf`, the system automatically moves older QR codes to cheaper storage tiers after 30 days of inactivity, preventing cost bloat as the database grows.

---

## Contacts & license

**Owner:** Filip Ermenkov — [f.ermenkov@gmail.com](mailto:f.ermenkov@gmail.com)\
**License:** This project is licensed under the [MIT License](LICENSE)