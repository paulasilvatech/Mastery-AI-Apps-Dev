# modules/webapp/main.tf - Web Application module implementation

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.85.0"
    }
  }
}

# App Service Plan
resource "azurerm_service_plan" "main" {
  name                = "asp-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku.size
  tags                = var.tags
}

# Web App
resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.app_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true
  tags                = var.tags

  site_config {
    always_on = var.app_service_plan_sku.tier != "Free" && var.app_service_plan_sku.tier != "Shared"
    
    application_stack {
      dotnet_version = "8.0"
    }
    
    ip_restriction {
      name       = "AllowAll"
      action     = "Allow"
      priority   = 100
      ip_address = "0.0.0.0/0"
    }
  }

  app_settings = merge(
    {
      "ASPNETCORE_ENVIRONMENT" = var.environment
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
    },
    var.app_settings
  )

  identity {
    type = "SystemAssigned"
  }
  
  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = var.database_connection_string
  }

  logs {
    application_logs {
      file_system_level = var.environment == "prod" ? "Warning" : "Information"
    }
    
    http_logs {
      file_system {
        retention_in_days = var.environment == "prod" ? 7 : 3
        retention_in_mb   = 100
      }
    }
  }
}

# Virtual Network Integration
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_linux_web_app.main.id
  subnet_id      = var.subnet_id
}

# Staging Slot (Production only)
resource "azurerm_linux_web_app_slot" "staging" {
  count           = var.enable_staging_slot ? 1 : 0
  name            = "staging"
  app_service_id  = azurerm_linux_web_app.main.id
  https_only      = true
  tags            = var.tags

  site_config {
    always_on = true
    
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = merge(
    {
      "ASPNETCORE_ENVIRONMENT" = "Staging"
      "WEBSITE_RUN_FROM_PACKAGE" = "1"
    },
    var.app_settings
  )

  identity {
    type = "SystemAssigned"
  }
}

# Auto-scaling (Production only)
resource "azurerm_monitor_autoscale_setting" "main" {
  count               = var.enable_autoscale ? 1 : 0
  name                = "autoscale-${var.app_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_service_plan.main.id
  enabled             = true

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.main.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
      custom_emails                         = var.alert_emails
    }
  }
}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "webapp" {
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_web_app.main.identity[0].tenant_id
  object_id    = azurerm_linux_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Key Vault Access Policy for Staging Slot
resource "azurerm_key_vault_access_policy" "staging" {
  count        = var.enable_staging_slot ? 1 : 0
  key_vault_id = var.key_vault_id
  tenant_id    = azurerm_linux_web_app_slot.staging[0].identity[0].tenant_id
  object_id    = azurerm_linux_web_app_slot.staging[0].identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
} 