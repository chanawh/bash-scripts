#!/bin/bash

# Prompt for a name for the Service Principal
read -p "Enter a name for the Service Principal: " SP_NAME

# Prompt for the role to assign
read -p "Enter the role to assign (default: Contributor): " ROLE
ROLE=${ROLE:-Contributor}

# Prompt for the scope (default to subscription level)
read -p "Enter the scope (default: current subscription): " SCOPE

# Login to Azure
echo "Logging into Azure..."
az login --only-show-errors > /dev/null

# Get subscription ID and tenant ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Use default scope if none provided
if [ -z "$SCOPE" ]; then
  SCOPE="/subscriptions/$SUBSCRIPTION_ID"
fi

# Create the service principal
echo "Creating service principal..."
SP_JSON=$(az ad sp create-for-rbac --name "$SP_NAME" --role "$ROLE" --scopes "$SCOPE" --only-show-errors)

# Extract client ID and secret securely
CLIENT_ID=$(echo "$SP_JSON" | jq -r .appId)
CLIENT_SECRET=$(echo "$SP_JSON" | jq -r .password)

# Export credentials silently
export ARM_SUBSCRIPTION_ID="$SUBSCRIPTION_ID"
export ARM_CLIENT_ID="$CLIENT_ID"
export ARM_CLIENT_SECRET="$CLIENT_SECRET"
export ARM_TENANT_ID="$TENANT_ID"

echo "✅ Service Principal '$SP_NAME' created and credentials exported to current shell."
echo "🔒 No secrets were printed or saved to disk."
