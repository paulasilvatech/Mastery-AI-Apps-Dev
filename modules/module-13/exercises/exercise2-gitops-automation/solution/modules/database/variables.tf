# modules/database/variables.tf - Database module variables

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "server_name" {
  description = "Name of the SQL server"
  type        = string
}

variable "database_name" {
  description = "Name of the database"
  type        = string
}

variable "admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
  sensitive   = true
}

variable "subnet_id" {
  description = "ID of the subnet for VNet integration"
  type        = string
}

variable "key_vault_id" {
  description = "ID of the Key Vault for storing secrets"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the database"
  type        = string
  default     = "Basic"
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "enable_geo_replication" {
  description = "Enable geo-replication for disaster recovery"
  type        = bool
  default     = false
}

variable "secondary_location" {
  description = "Location for secondary/DR server"
  type        = string
  default     = "West US 2"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 