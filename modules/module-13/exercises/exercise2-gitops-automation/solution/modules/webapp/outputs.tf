# modules/webapp/outputs.tf - Web Application module outputs

output "app_service_id" {
  description = "ID of the App Service"
  value       = azurerm_linux_web_app.main.id
}

output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "url" {
  description = "Default URL of the web app"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "default_hostname" {
  description = "Default hostname of the web app"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "identity_principal_id" {
  description = "Principal ID of the web app's managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "identity_tenant_id" {
  description = "Tenant ID of the web app's managed identity"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}

output "staging_url" {
  description = "URL of the staging slot"
  value       = var.enable_staging_slot ? "https://${azurerm_linux_web_app_slot.staging[0].default_hostname}" : null
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses of the web app"
  value       = split(",", azurerm_linux_web_app.main.outbound_ip_addresses)
} 