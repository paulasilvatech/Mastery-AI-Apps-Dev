# modules/database/main.tf - Database module implementation

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
  }
}

# Random password for SQL admin
resource "random_password" "sql_admin" {
  length  = 32
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.server_name}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = data.azurerm_client_config.current.object_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }
}

# SQL Database
resource "azurerm_mssql_database" "main" {
  name         = var.database_name
  server_id    = azurerm_mssql_server.main.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  sku_name     = var.sku_name
  tags         = var.tags

  threat_detection_policy {
    state                      = "Enabled"
    storage_endpoint           = azurerm_storage_account.audit.primary_blob_endpoint
    storage_account_access_key = azurerm_storage_account.audit.primary_access_key
    retention_days             = var.backup_retention_days
  }

  short_term_retention_policy {
    retention_days = var.backup_retention_days
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
    yearly_retention  = "P1Y"
    week_of_year      = 1
  }
}

# Storage Account for audit logs
resource "azurerm_storage_account" "audit" {
  name                     = "staudit${replace(var.server_name, "-", "")}${var.environment}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  blob_properties {
    delete_retention_policy {
      days = var.backup_retention_days
    }
  }
}

# Firewall Rules
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Virtual Network Rule
resource "azurerm_mssql_virtual_network_rule" "main" {
  name      = "vnet-rule-${var.environment}"
  server_id = azurerm_mssql_server.main.id
  subnet_id = var.subnet_id
}

# Geo-replication (Production only)
resource "azurerm_mssql_server" "secondary" {
  count                        = var.enable_geo_replication ? 1 : 0
  name                         = "sql-${var.server_name}-dr"
  resource_group_name          = var.resource_group_name
  location                     = var.secondary_location
  version                      = "12.0"
  administrator_login          = var.admin_username
  administrator_login_password = random_password.sql_admin.result
  minimum_tls_version          = "1.2"
  tags                         = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_mssql_database" "secondary" {
  count                       = var.enable_geo_replication ? 1 : 0
  name                        = var.database_name
  server_id                   = azurerm_mssql_server.secondary[0].id
  create_mode                 = "Secondary"
  creation_source_database_id = azurerm_mssql_database.main.id
  tags                        = var.tags
}

# Store credentials in Key Vault
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password-${var.environment}"
  value        = random_password.sql_admin.result
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string-${var.environment}"
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.admin_username};Password=${random_password.sql_admin.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = var.key_vault_id
  tags         = var.tags
}

# Data source for current client config
data "azurerm_client_config" "current" {} 