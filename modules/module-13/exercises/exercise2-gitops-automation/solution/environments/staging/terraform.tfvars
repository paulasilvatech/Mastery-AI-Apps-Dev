# terraform.tfvars - Staging environment configuration

environment  = "staging"
project_name = "gitops-demo"
location     = "East US 2"

# VNet configuration
vnet_address_space = ["10.1.0.0/16"]

# App Service configuration
app_service_plan_sku = {
  tier = "Standard"
  size = "S1"
}

# Database configuration
database_sku = "S0"

# Tags
additional_tags = {
  CostCenter = "QA"
  Owner      = "QATeam"
} 