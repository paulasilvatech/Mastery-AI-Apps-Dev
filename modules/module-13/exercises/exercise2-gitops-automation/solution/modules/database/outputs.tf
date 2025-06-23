# modules/database/outputs.tf - Database module outputs

output "server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
}

output "server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "database_id" {
  description = "ID of the database"
  value       = azurerm_mssql_database.main.id
}

output "database_name" {
  description = "Name of the database"
  value       = azurerm_mssql_database.main.name
}

output "connection_string" {
  description = "Connection string for the database"
  value       = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.main.name};Persist Security Info=False;User ID=${var.admin_username};Password=${random_password.sql_admin.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  sensitive   = true
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
  sensitive   = true
}

output "secondary_server_fqdn" {
  description = "FQDN of the secondary SQL Server (if geo-replication is enabled)"
  value       = var.enable_geo_replication ? azurerm_mssql_server.secondary[0].fully_qualified_domain_name : null
} 