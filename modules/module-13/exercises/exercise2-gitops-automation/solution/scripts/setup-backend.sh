#!/bin/bash
# setup-backend.sh - Script to configure Terraform backend

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Terraform backend storage...${NC}"

# Variables
STATE_RESOURCE_GROUP="rg-terraform-state"
LOCATION="eastus2"
RANDOM_SUFFIX=$(date +%s | tail -c 5)
STORAGE_ACCOUNT_NAME="tfstate${RANDOM_SUFFIX}"
CONTAINER_NAME="tfstate"

echo -e "${YELLOW}📍 Configuration:${NC}"
echo "   Resource Group: $STATE_RESOURCE_GROUP"
echo "   Location: $LOCATION"
echo "   Storage Account: $STORAGE_ACCOUNT_NAME"
echo "   Container: $CONTAINER_NAME"

# Check if logged in to Azure
echo -e "\n${YELLOW}🔐 Checking Azure login...${NC}"
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ Not logged in to Azure. Please run 'az login' first.${NC}"
    exit 1
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
echo -e "${GREEN}✅ Logged in to subscription: $SUBSCRIPTION_ID${NC}"

# Create resource group
echo -e "\n${YELLOW}📦 Creating resource group...${NC}"
if az group exists --name $STATE_RESOURCE_GROUP --output tsv | grep -q "true"; then
    echo -e "${GREEN}✅ Resource group already exists${NC}"
else
    az group create \
        --name $STATE_RESOURCE_GROUP \
        --location $LOCATION \
        --tags Purpose=TerraformState Module=13 \
        --output none
    echo -e "${GREEN}✅ Resource group created${NC}"
fi

# Create storage account
echo -e "\n${YELLOW}💾 Creating storage account...${NC}"
az storage account create \
    --name $STORAGE_ACCOUNT_NAME \
    --resource-group $STATE_RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --tags Purpose=TerraformState Module=13 \
    --output none

echo -e "${GREEN}✅ Storage account created${NC}"

# Get storage account key
echo -e "\n${YELLOW}🔑 Retrieving storage account key...${NC}"
ACCOUNT_KEY=$(az storage account keys list \
    --resource-group $STATE_RESOURCE_GROUP \
    --account-name $STORAGE_ACCOUNT_NAME \
    --query '[0].value' -o tsv)

# Create blob container
echo -e "\n${YELLOW}📁 Creating blob container...${NC}"
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT_NAME \
    --account-key $ACCOUNT_KEY \
    --auth-mode key \
    --output none

echo -e "${GREEN}✅ Container created${NC}"

# Enable versioning
echo -e "\n${YELLOW}📚 Enabling blob versioning...${NC}"
az storage account blob-service-properties update \
    --account-name $STORAGE_ACCOUNT_NAME \
    --resource-group $STATE_RESOURCE_GROUP \
    --enable-versioning true \
    --output none

echo -e "${GREEN}✅ Versioning enabled${NC}"

# Enable soft delete
echo -e "\n${YELLOW}🗑️  Configuring soft delete...${NC}"
az storage account blob-service-properties update \
    --account-name $STORAGE_ACCOUNT_NAME \
    --resource-group $STATE_RESOURCE_GROUP \
    --enable-delete-retention true \
    --delete-retention-days 30 \
    --output none

echo -e "${GREEN}✅ Soft delete configured (30 days)${NC}"

# Create backend configuration file
echo -e "\n${YELLOW}📝 Creating backend configuration...${NC}"
cat > backend-config.txt <<EOF
BACKEND_RG=$STATE_RESOURCE_GROUP
BACKEND_SA=$STORAGE_ACCOUNT_NAME
BACKEND_CONTAINER=$CONTAINER_NAME
BACKEND_KEY=$ACCOUNT_KEY
EOF

# Create example backend.tf
cat > backend.tf.example <<EOF
terraform {
  backend "azurerm" {
    resource_group_name  = "$STATE_RESOURCE_GROUP"
    storage_account_name = "$STORAGE_ACCOUNT_NAME"
    container_name       = "$CONTAINER_NAME"
    key                  = "env/terraform.tfstate"
  }
}
EOF

# Display summary
echo -e "\n${GREEN}✅ Backend storage created successfully!${NC}"
echo -e "\n${YELLOW}📋 Summary:${NC}"
echo "   Resource Group: $STATE_RESOURCE_GROUP"
echo "   Storage Account: $STORAGE_ACCOUNT_NAME"
echo "   Container: $CONTAINER_NAME"

echo -e "\n${YELLOW}🚀 Next steps:${NC}"
echo "1. Initialize Terraform with backend config:"
echo -e "${GREEN}   terraform init \\
      -backend-config=\"resource_group_name=$STATE_RESOURCE_GROUP\" \\
      -backend-config=\"storage_account_name=$STORAGE_ACCOUNT_NAME\" \\
      -backend-config=\"container_name=$CONTAINER_NAME\" \\
      -backend-config=\"key=<environment>.terraform.tfstate\"${NC}"

echo -e "\n2. Or use the saved configuration:"
echo -e "${GREEN}   export \$(cat backend-config.txt | xargs)${NC}"

echo -e "\n${YELLOW}💡 Tip:${NC} Configuration saved to 'backend-config.txt' and example to 'backend.tf.example'"

# Create GitHub Actions secrets script
cat > create-github-secrets.sh <<EOF
#!/bin/bash
# Script to create GitHub secrets for the backend

echo "Creating GitHub secrets..."
gh secret set BACKEND_RG --body "$STATE_RESOURCE_GROUP"
gh secret set BACKEND_SA --body "$STORAGE_ACCOUNT_NAME"
gh secret set BACKEND_CONTAINER --body "$CONTAINER_NAME"
echo "✅ GitHub secrets created"
EOF

chmod +x create-github-secrets.sh
echo -e "\n${YELLOW}🔐 To create GitHub secrets, run:${NC} ./create-github-secrets.sh" 