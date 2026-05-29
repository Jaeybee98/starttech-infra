# StartTech Infrastructure as Code (IaC)

This repository contains the complete, modularized infrastructure configuration for the StartTech full-stack application. The entire environment is provisioned on AWS using Terraform, featuring a secure, highly available, three-tier cloud architecture.

---

## 📁 Repository Structure

```text
starttech-infra/
├── .github/
│   └── workflows/
│       └── infrastructure-deploy.yml   # Automated validation & planning pipeline
├── terraform/
│   ├── main.tf                         # Root entry point declaring modules
│   ├── variables.tf                    # Root environment variable schema
│   ├── outputs.tf                      # Output definitions (ALB URL, CDN URL, etc.)
│   ├── modules/
│   │   ├── networking/                 # VPC, Subnets, NAT Gateway, Route Tables
│   │   ├── compute/                    # ASG, Launch Template, ALB, Redis Cluster
│   │   ├── storage/                    # S3 Frontend Bucket, CloudFront OAC
│   │   └── monitoring/                 # CloudWatch Log Groups, Metric Alarms
│   └── terraform.tfvars.example        # Reference for custom parameter inputs
├── scripts/
│   └── deploy-infrastructure.sh        # Local automated deployment wrapper script
├── monitoring/
│   ├── cloudwatch-dashboard.json       # Metrics visualization dashboard template
│   ├── alarm-definitions.json          # Metric alarm thresholds declaration
│   └── log-insights-queries.txt        # Pre-built Log Insights debugging queries
└── README.md

🛠️ Core Infrastructure Components
Networking Tiers: A custom VPC encompassing 2 Public Subnets (assigned to the Load Balancer) and 2 Private Subnets (housing the backend EC2 instances and caching layer) mapped across two Availability Zones for fault isolation.

Elastic Compute Scaling: Auto Scaling Group (ASG) utilizing an Amazon Linux 2023 Launch Template, configured to dynamically scale backend EC2 instances between 1 and 3 instances based on production demands.

Static Content Delivery (CDN): Frontend web assets are securely isolated in a private S3 bucket. Public access is entirely disabled, forcing all traffic through an AWS CloudFront Distribution leveraging Origin Access Control (OAC) for high-speed edge delivery.

Caching & Persistence: A private single-node Amazon ElastiCache Redis cluster for fast session handling, paired with an external MongoDB Atlas Cloud database setup.

🚀 Deployment Instructions
Prerequisites
Installed Terraform CLI (v1.7.0 or newer).

Installed AWS CLI configured with appropriate administrative credentials.

An active MongoDB Atlas Cluster with an established database user and network access enabled (0.0.0.0/0).

Local Deployment
You can easily provision or update the complete cloud architecture by running the automated deployment shell wrapper:

# Grant execution permissions if not already active
chmod +x scripts/deploy-infrastructure.sh

# Run the deployment pipeline script
./scripts/deploy-infrastructure.sh

CI/CD Infrastructure Pipeline
This repository is configured with an automated GitHub Actions Workflow (infrastructure-deploy.yml).

Every Pull Request or Push targeting the main branch that modifies files inside the terraform/ directory will automatically trigger the pipeline.

The pipeline checks structural code formatting compliance (terraform fmt), validates logical syntax (terraform validate), and compiles a live dry-run execution blueprint (terraform plan).

🔐 Security Features
Least-Privilege Network Access: Security Groups form a strict firewall perimeter. The backend compute instances accept traffic only when routed directly through the Application Load Balancer. The Redis cluster accepts requests only from the backend application instances.

IAM Controls: Instances use a dedicated IAM profile mapped with strict CloudWatchAgentServerPolicy parameters to isolate logging mechanisms without granting wider account privileges.
