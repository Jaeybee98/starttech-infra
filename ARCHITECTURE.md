# StartTech Full-Stack Production Architecture

This document details the production-grade, highly available, and secure infrastructure designed for the StartTech full-stack application using AWS and MongoDB Atlas.

---

## Architecture Overview

The system is split into three highly isolated operational tiers to ensure security, fault tolerance, and predictable scaling:

[ Public Internet ]
             │
             ▼
   ┌──────────────────┐
   │ CloudFront CDN   │ ───► Serves Static Frontend (S3)
   └──────────────────┘
             │ (API Requests)
             ▼
 ┌──────────────────────┐
 │ Application Load     │ (Public Subnets)
 │ Balancer (ALB)       │
 └──────────────────────┘
             │
    ┌────────┴────────┐ (Private Subnets)
    ▼                 ▼
┌───────────┐     ┌───────────┐
│ Go App    │     │ Go App    │ (Auto Scaling Group)
│ Instance  │     │ Instance  │
└───────────┘     └───────────┘
│                 │
├─────────────────┤
▼                 ▼
┌───────────────┐ ┌───────────────┐
│ ElastiCache   │ │ MongoDB Atlas │ (Managed Data Tier)
│ Redis Cluster │ │ (Cloud Cluster)
└───────────────┘ └───────────────┘


---

## Tier-by-Tier Breakdown

### 1. Presentation Tier (Frontend Hosting)
* **AWS S3:** Houses the compiled production React application. Content public access is strictly blocked via S3 Block Public Access to prevent direct asset tampering.
* **AWS CloudFront (CDN):** Acts as the global edge-delivery layer. It interfaces with the private S3 bucket using **Origin Access Control (OAC)**, ensuring that assets can only be pulled through CloudFront via HTTPS.

### 2. Logic Tier (Backend API Compute)
* **Application Load Balancer (ALB):** Placed across two Public Subnets (`10.0.1.0/24`, `10.0.2.0/24`). It terminates public web traffic on port 80 and routes verified traffic to the backend instances on port 8080.
* **Auto Scaling Group (ASG):** Deployed across two Private Subnets (`10.0.11.0/24`, `10.0.12.0/24`). It dynamically handles traffic spikes by scaling Amazon Linux 2023 EC2 instances between a minimum of 1 and a maximum of 3.
* **Network Isolation:** Backend instances have **no public IP addresses**. They utilize an AWS NAT Gateway for secure outbound internet communication (e.g., pulling application patches or communicating with MongoDB Atlas).

### 3. Data & Caching Tier
* **Amazon ElastiCache (Redis):** A dedicated single-node Redis 7 cluster deployed in the private subnets to handle session state and application caching. Protected by a security group allowing ingress traffic **only** from the backend EC2 security group.
* **MongoDB Atlas:** A managed cloud database cluster handling relational data persistence. Access is constrained via database user authentication and network access protocol configurations.

---

## Security Implementation Matrix

| Component | Security Group Ingress Rules | Security Group Egress Rules |
| :--- | :--- | :--- |
| **ALB** | Port 80 (`0.0.0.0/0`) | Everywhere (`0.0.0.0/0`) |
| **EC2 Backend** | Port 8080 (Restricted to **ALB SG**) | Everywhere (`0.0.0.0/0`) |
| **ElastiCache Redis** | Port 6379 (Restricted to **EC2 Backend SG**) | Everywhere (`0.0.0.0/0`) |

---

## Monitoring and Observability Design
* **CloudWatch Logs:** EC2 instances run the native `amazon-cloudwatch-agent` daemon to securely ship application runtime streams directly to the central Log Group `/aws/starttech/backend-application`.
* **Telemetry Alarms:** A CloudWatch metric monitor tracks average cluster strain, raising an alert condition if CPU metrics exceed **80%** across two consecutive evaluation periods.
