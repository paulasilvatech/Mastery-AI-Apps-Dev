# terraform.tfvars - Development environment configuration

environment  = "dev"
project_name = "gitops-demo"
location     = "East US 2"

# VNet configuration
vnet_address_space = ["10.0.0.0/16"]

# App Service configuration
app_service_plan_sku = {
  tier = "Free"
  size = "F1"
}

# Database configuration
database_sku = "Basic"

# Tags
additional_tags = {
  CostCenter = "Development"
  Owner      = "DevTeam"
} 