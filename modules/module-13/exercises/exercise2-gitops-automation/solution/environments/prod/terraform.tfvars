# terraform.tfvars - Production environment configuration

environment  = "prod"
project_name = "gitops-demo"
location     = "East US 2"

# VNet configuration
vnet_address_space = ["10.2.0.0/16"]

# App Service configuration
app_service_plan_sku = {
  tier = "PremiumV2"
  size = "P1v2"
}

# Database configuration
database_sku = "S3"

# Security
allowed_ips = [
  "20.42.0.0/16",  # Corporate network
  "52.168.0.0/16"  # Branch offices
]

# Tags
additional_tags = {
  CostCenter  = "Production"
  Owner       = "ProdOps"
  Compliance  = "PCI-DSS"
  Environment = "Production"
} 