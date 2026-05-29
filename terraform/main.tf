terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. Networking Tier
module "networking" {
  source = "./modules/networking"
}

# 2. Storage & Static CDN Tier
module "storage" {
  source       = "./modules/storage"
  project_name = "starttech"
  domain_name  = "starttech-frontend-app-jaeybee98"
}

# 3. Compute & Caching Tier (Includes Auto Scaling, ALB, and Redis)
module "compute" {
  source             = "./modules/compute"
  project_name       = "starttech"
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  private_subnet_ids = module.networking.private_subnet_ids
  instance_type      = "t3.micro"
}

# 4. Monitoring & Observability Tier
module "monitoring" {
  source       = "./modules/monitoring"
  project_name = "starttech"
}
# Triggering live infrastructure build deployment
