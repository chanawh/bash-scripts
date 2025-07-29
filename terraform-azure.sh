#!/bin/bash

# Exit on any error
set -e

echo "Updating system and installing dependencies..."
sudo dnf install -y dnf-plugins-core curl unzip git

echo "Adding HashiCorp repository for Terraform..."
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

echo "Installing Terraform..."
sudo dnf install -y terraform

echo "Installing Azure CLI..."
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf install -y azure-cli

echo "Verifying installations..."
terraform -version
az version

echo "Logging into Azure..."
az login

echo "Creating Terraform project directory..."
mkdir -p ~/terraform-azure-demo
cd ~/terraform-azure-demo

echo "Creating basic Terraform configuration for Azure Resource Group..."
cat <<EOF > main.tf
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}
EOF

echo "Terraform project setup complete. Run the following commands to deploy:"
echo "cd ~/terraform-azure-demo"
echo "terraform init"
echo "terraform plan"
echo "terraform apply"
