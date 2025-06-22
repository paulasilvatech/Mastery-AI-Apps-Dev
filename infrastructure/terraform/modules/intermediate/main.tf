# Terraform module for Intermediate track (Modules 6-10)
# Creates web application and API resources

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

# App Service Plan
resource "azurerm_service_plan" "intermediate" {
  name                = "asp-module${var.module_number}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  os_type             = "Linux"
  sku_name           = var.app_service_sku

  tags = var.tags
}

# Web App
resource "azurerm_linux_web_app" "intermediate" {
  name                = "app-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.intermediate.id

  site_config {
    always_on = var.environment != "dev"
    
    application_stack {
      python_version = var.python_version
    }
    
    app_command_line = "python app.py"
    
    cors {
      allowed_origins = var.cors_allowed_origins
      support_credentials = false
    }
  }

  app_settings = {
    "ENVIRONMENT"                = var.environment
    "MODULE_NUMBER"              = var.module_number
    "DATABASE_URL"               = azurerm_mssql_database.intermediate.id
    "REDIS_URL"                  = var.module_number >= 8 ? "redis://${azurerm_redis_cache.intermediate[0].hostname}:${azurerm_redis_cache.intermediate[0].ssl_port}" : ""
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "WEBSITE_HEALTHCHECK_MAXPINGFAILURES" = "3"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }

  identity {
    type = "SystemAssigned"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    
    application_logs {
      file_system_level = "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = var.log_retention_days
        retention_in_mb   = 35
      }
    }
  }

  tags = var.tags
}

# SQL Server
resource "azurerm_mssql_server" "intermediate" {
  name                         = "sql-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
  minimum_tls_version         = "1.2"
  
  azuread_administrator {
    login_username = var.sql_aad_admin_login
    object_id      = var.sql_aad_admin_object_id
  }

  tags = var.tags
}

# SQL Database
resource "azurerm_mssql_database" "intermediate" {
  name           = "sqldb-module${var.module_number}-${var.environment}"
  server_id      = azurerm_mssql_server.intermediate.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.sql_database_max_size_gb
  sku_name       = var.sql_database_sku
  zone_redundant = var.environment == "prod"

  threat_detection_policy {
    state                      = "Enabled"
    email_account_admins       = "Enabled"
    email_addresses            = [var.security_email]
    retention_days             = 30
    storage_account_access_key = var.storage_account_access_key
    storage_endpoint           = var.storage_account_blob_endpoint
  }

  tags = var.tags
}

# SQL Firewall Rule for Azure Services
resource "azurerm_mssql_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.intermediate.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Redis Cache (Module 8+)
resource "azurerm_redis_cache" "intermediate" {
  count               = var.module_number >= 8 ? 1 : 0
  name                = "redis-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  family              = var.redis_family
  sku_name           = var.redis_sku_name
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
    maxmemory_reserved = var.redis_maxmemory_reserved
    maxmemory_delta    = var.redis_maxmemory_delta
    maxmemory_policy   = "allkeys-lru"
  }

  patch_schedule {
    day_of_week    = "Sunday"
    start_hour_utc = 2
  }

  tags = var.tags
}

# API Management (Module 9+)
resource "azurerm_api_management" "intermediate" {
  count               = var.module_number >= 9 ? 1 : 0
  name                = "apim-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.api_management_publisher_name
  publisher_email     = var.api_management_publisher_email

  sku_name = var.api_management_sku

  identity {
    type = "SystemAssigned"
  }

  policy {
    xml_content = <<XML
<policies>
  <inbound>
    <cors>
      <allowed-origins>
        <origin>*</origin>
      </allowed-origins>
      <allowed-methods>
        <method>GET</method>
        <method>POST</method>
        <method>PUT</method>
        <method>DELETE</method>
      </allowed-methods>
      <allowed-headers>
        <header>*</header>
      </allowed-headers>
    </cors>
  </inbound>
  <backend>
    <forward-request />
  </backend>
  <outbound />
  <on-error />
</policies>
XML
  }

  tags = var.tags
}

# API Management API
resource "azurerm_api_management_api" "web_api" {
  count               = var.module_number >= 9 ? 1 : 0
  name                = "workshop-api"
  resource_group_name = var.resource_group_name
  api_management_name = azurerm_api_management.intermediate[0].name
  revision            = "1"
  display_name        = "Workshop API"
  path                = "api/v1"
  protocols           = ["https"]
  service_url         = "https://${azurerm_linux_web_app.intermediate.default_hostname}"

  import {
    content_format = "openapi+json"
    content_value = jsonencode({
      openapi = "3.0.0"
      info = {
        title   = "Workshop API"
        version = "1.0.0"
      }
      paths = {
        "/health" = {
          get = {
            summary = "Health check endpoint"
            responses = {
              "200" = {
                description = "Service is healthy"
              }
            }
          }
        }
      }
    })
  }
}

# Storage Account for static files
resource "azurerm_storage_account" "intermediate" {
  name                     = "st${var.module_number}${var.environment}${substr(var.suffix, 0, 6)}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.storage_replication_type
  
  min_tls_version                = "TLS1_2"
  enable_https_traffic_only      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
    
    delete_retention_policy {
      days = 7
    }
    
    versioning_enabled = true
  }

  tags = var.tags
}

# Storage Container for uploads
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.intermediate.name
  container_access_type = "private"
}

# Static Website (Module 7+)
resource "azurerm_static_web_app" "intermediate" {
  count               = var.module_number >= 7 ? 1 : 0
  name                = "swa-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.static_web_app_location
  sku_tier           = var.static_web_app_sku_tier
  sku_size           = var.static_web_app_sku_size

  app_settings = {
    "API_URL" = "https://${azurerm_linux_web_app.intermediate.default_hostname}"
  }

  tags = var.tags
}

# Function App (Module 10+)
resource "azurerm_linux_function_app" "intermediate" {
  count               = var.module_number >= 10 ? 1 : 0
  name                = "func-module${var.module_number}-${var.environment}-${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  service_plan_id     = azurerm_service_plan.intermediate.id
  
  storage_account_name       = azurerm_storage_account.intermediate.name
  storage_account_access_key = azurerm_storage_account.intermediate.primary_access_key

  site_config {
    application_stack {
      python_version = var.python_version
    }
    
    cors {
      allowed_origins = var.cors_allowed_origins
    }
    
    application_insights_connection_string = var.app_insights_connection_string
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = var.app_insights_connection_string
    "DATABASE_URL"                          = azurerm_mssql_database.intermediate.id
    "REDIS_URL"                            = var.module_number >= 8 ? "redis://${azurerm_redis_cache.intermediate[0].hostname}:${azurerm_redis_cache.intermediate[0].ssl_port}" : ""
    "ENVIRONMENT"                          = var.environment
    "MODULE_NUMBER"                        = var.module_number
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Service Bus (Module 10+)
resource "azurerm_servicebus_namespace" "intermediate" {
  count               = var.module_number >= 10 ? 1 : 0
  name                = "sb-module${var.module_number}-${var.environment}-${var.suffix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                = var.service_bus_sku

  tags = var.tags
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "orders" {
  count        = var.module_number >= 10 ? 1 : 0
  name         = "orders"
  namespace_id = azurerm_servicebus_namespace.intermediate[0].id

  enable_partitioning = true
}

# Role Assignments
resource "azurerm_role_assignment" "web_app_sql" {
  scope                = azurerm_mssql_server.intermediate.id
  role_definition_name = "SQL DB Contributor"
  principal_id         = azurerm_linux_web_app.intermediate.identity[0].principal_id
}

resource "azurerm_role_assignment" "web_app_storage" {
  scope                = azurerm_storage_account.intermediate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.intermediate.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_app_storage" {
  count                = var.module_number >= 10 ? 1 : 0
  scope                = azurerm_storage_account.intermediate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.intermediate[0].identity[0].principal_id
}

# Application Insights Web Test
resource "azurerm_application_insights_web_test" "health_check" {
  name                    = "health-check-${var.environment}"
  location                = var.location
  resource_group_name     = var.resource_group_name
  application_insights_id = var.app_insights_id
  kind                    = "ping"
  frequency               = 300
  timeout                 = 60
  enabled                 = true
  retry_enabled           = true
  
  geo_locations = ["us-ca-sjc-azr", "us-tx-sn1-azr"]

  configuration = <<XML
<WebTest Name="health-check" Id="${uuidv4()}" Enabled="True" CssProjectStructure="" CssIteration="" Timeout="60" WorkItemIds="" xmlns="http://microsoft.com/schemas/VisualStudio/TeamTest/2010" Description="" CredentialUserName="" CredentialPassword="" PreAuthenticate="True" Proxy="default" StopOnError="False" RecordedResultFile="" ResultsLocale="">
  <Items>
    <Request Method="GET" Guid="${uuidv4()}" Version="1.1" Url="https://${azurerm_linux_web_app.intermediate.default_hostname}/health" ThinkTime="0" Timeout="60" ParseDependentRequests="False" FollowRedirects="True" RecordResult="True" Cache="False" ResponseTimeGoal="0" Encoding="utf-8" ExpectedHttpStatusCode="200" ExpectedResponseUrl="" ReportingName="" IgnoreHttpStatusCode="False" />
  </Items>
</WebTest>
XML

  tags = var.tags
}
