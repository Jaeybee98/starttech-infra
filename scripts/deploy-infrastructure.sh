#!/bin/bash
set -e # Exit immediately if any command exits with a non-zero status

echo "===================================================="
echo "🚀 StartTech: Deploying Production Infrastructure"
echo "===================================================="

cd "$(dirname "$0")/../terraform"

echo "Step 1: Initializing Terraform modules and providers..."
terraform init

echo "Step 2: Validating template syntax..."
if terraform validate; then
    echo "✅ Validation successful!"
else
    echo "❌ Validation failed. Please check your configurations."
    exit 1
fi

echo "Step 3: Generating execution plan..."
terraform plan -out=tfplan

echo "Step 4: Applying infrastructure deployment..."
# The -auto-approve flag ensures non-interactive runs (critical for CI/CD)
terraform apply -auto-approve tfplan

echo "===================================================="
echo "🎉 Infrastructure successfully deployed!"
echo "===================================================="
