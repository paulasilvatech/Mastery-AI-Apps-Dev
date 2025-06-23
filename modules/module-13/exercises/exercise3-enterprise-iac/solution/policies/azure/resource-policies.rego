# resource-policies.rego - Complete OPA policies for Azure resources

package azure.resources

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# Required tags for all resources
required_tags := {
    "Environment",
    "ManagedBy",
    "CostCenter",
    "Owner",
    "Module",
    "CreatedDate",
    "Purpose"
}

# Allowed resource types by environment
allowed_resource_types := {
    "dev": [
        "Microsoft.Web/serverfarms",
        "Microsoft.Web/sites",
        "Microsoft.Web/sites/slots",
        "Microsoft.Storage/storageAccounts",
        "Microsoft.Sql/servers",
        "Microsoft.Sql/servers/databases",
        "Microsoft.KeyVault/vaults",
        "Microsoft.Insights/components",
        "Microsoft.Network/virtualNetworks",
        "Microsoft.Network/networkSecurityGroups",
        "Microsoft.Network/publicIPAddresses",
        "Microsoft.ContainerRegistry/registries",
        "Microsoft.ContainerService/managedClusters"
    ],
    "staging": [
        "Microsoft.Web/serverfarms",
        "Microsoft.Web/sites",
        "Microsoft.Web/sites/slots",
        "Microsoft.Storage/storageAccounts",
        "Microsoft.Sql/servers",
        "Microsoft.Sql/servers/databases",
        "Microsoft.KeyVault/vaults",
        "Microsoft.Insights/components",
        "Microsoft.Network/virtualNetworks",
        "Microsoft.Network/networkSecurityGroups",
        "Microsoft.Network/publicIPAddresses",
        "Microsoft.Cdn/profiles",
        "Microsoft.ContainerRegistry/registries",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.Cache/redis"
    ],
    "prod": [
        "Microsoft.Web/serverfarms",
        "Microsoft.Web/sites",
        "Microsoft.Web/sites/slots",
        "Microsoft.Storage/storageAccounts",
        "Microsoft.Sql/servers",
        "Microsoft.Sql/servers/databases",
        "Microsoft.KeyVault/vaults",
        "Microsoft.Insights/components",
        "Microsoft.Network/virtualNetworks",
        "Microsoft.Network/networkSecurityGroups",
        "Microsoft.Network/publicIPAddresses",
        "Microsoft.Cdn/profiles",
        "Microsoft.Network/frontdoors",
        "Microsoft.Network/applicationGateways",
        "Microsoft.ContainerRegistry/registries",
        "Microsoft.ContainerService/managedClusters",
        "Microsoft.Cache/redis",
        "Microsoft.Network/trafficManagerProfiles",
        "Microsoft.Network/privateDnsZones"
    ]
}

# Cost limits by environment (monthly USD)
cost_limits := {
    "dev": 500,
    "staging": 2000,
    "prod": 10000
}

# Validate resource naming convention
deny[msg] {
    resource := input.resource_changes[_]
    not regex.match("^[a-z0-9-]+$", resource.change.after.name)
    msg := sprintf("Resource '%s' name must contain only lowercase letters, numbers, and hyphens", [resource.address])
}

# Ensure name doesn't start or end with hyphen
deny[msg] {
    resource := input.resource_changes[_]
    regex.match("^-|-$", resource.change.after.name)
    msg := sprintf("Resource '%s' name cannot start or end with a hyphen", [resource.address])
}

# Ensure all required tags are present
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    resource_tags := object.get(resource.change.after, "tags", {})
    missing_tags := required_tags - {tag | resource_tags[tag]}
    count(missing_tags) > 0
    msg := sprintf("Resource '%s' missing required tags: %v", [resource.address, missing_tags])
}

# Validate specific tag values
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    env := resource.change.after.tags.Environment
    not env in ["dev", "staging", "prod"]
    msg := sprintf("Resource '%s' has invalid Environment tag: %s", [resource.address, env])
}

# Validate resource types for environment
deny[msg] {
    resource := input.resource_changes[_]
    env := resource.change.after.tags.Environment
    allowed := allowed_resource_types[env]
    not resource.type in allowed
    msg := sprintf("Resource type '%s' not allowed in %s environment", [resource.type, env])
}

# Enforce HTTPS for web apps
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_linux_web_app"
    resource.change.after.https_only != true
    msg := sprintf("Web app '%s' must have HTTPS only enabled", [resource.address])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_windows_web_app"
    resource.change.after.https_only != true
    msg := sprintf("Web app '%s' must have HTTPS only enabled", [resource.address])
}

# Enforce minimum TLS version for web apps
deny[msg] {
    resource := input.resource_changes[_]
    resource.type in ["azurerm_linux_web_app", "azurerm_windows_web_app"]
    site_config := resource.change.after.site_config[0]
    site_config.minimum_tls_version != "1.2"
    msg := sprintf("Web app '%s' must use TLS 1.2 or higher", [resource.address])
}

# Enforce encryption for storage accounts
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.min_tls_version != "TLS1_2"
    msg := sprintf("Storage account '%s' must use TLS 1.2 or higher", [resource.address])
}

# Ensure storage accounts have secure transfer enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_storage_account"
    resource.change.after.enable_https_traffic_only != true
    msg := sprintf("Storage account '%s' must have secure transfer enabled", [resource.address])
}

# Ensure Key Vaults have soft delete enabled
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_key_vault"
    resource.change.after.soft_delete_retention_days < 7
    msg := sprintf("Key Vault '%s' must have soft delete enabled with at least 7 days retention", [resource.address])
}

# Ensure production Key Vaults have purge protection
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_key_vault"
    resource.change.after.tags.Environment == "prod"
    resource.change.after.purge_protection_enabled != true
    msg := sprintf("Production Key Vault '%s' must have purge protection enabled", [resource.address])
}

# Validate SQL Server security settings
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_mssql_server"
    resource.change.after.minimum_tls_version != "1.2"
    msg := sprintf("SQL Server '%s' must use TLS 1.2 or higher", [resource.address])
}

# Ensure SQL databases have transparent data encryption
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_mssql_database"
    transparent_data_encryption := resource.change.after.transparent_data_encryption[_]
    transparent_data_encryption.state != "Enabled"
    msg := sprintf("SQL Database '%s' must have transparent data encryption enabled", [resource.address])
}

# Validate network security group rules
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_network_security_rule"
    resource.change.after.source_address_prefix == "*"
    resource.change.after.destination_port_range == "*"
    resource.change.after.access == "Allow"
    msg := sprintf("Network security rule '%s' is too permissive (allows all traffic)", [resource.address])
}

# Validate estimated costs
deny[msg] {
    env := input.environment
    estimated_cost := to_number(input.cost_estimate)
    limit := cost_limits[env]
    estimated_cost > limit
    msg := sprintf("Estimated monthly cost $%.2f exceeds %s environment limit of $%.2f", [estimated_cost, env, limit])
}

# Ensure diagnostic settings for production resources
deny[msg] {
    resource := input.resource_changes[_]
    resource.change.after.tags.Environment == "prod"
    resource.type in [
        "azurerm_linux_web_app",
        "azurerm_windows_web_app",
        "azurerm_mssql_database",
        "azurerm_storage_account"
    ]
    # Check if there's a corresponding diagnostic setting
    diagnostic_setting_types := {r.type | r := input.resource_changes[_]}
    not "azurerm_monitor_diagnostic_setting" in diagnostic_setting_types
    msg := sprintf("Production resource '%s' must have diagnostic settings configured", [resource.address])
}

# Validate backup retention for production databases
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "azurerm_mssql_database"
    resource.change.after.tags.Environment == "prod"
    short_term_retention := resource.change.after.short_term_retention_policy[0]
    short_term_retention.retention_days < 35
    msg := sprintf("Production database '%s' must have at least 35 days backup retention", [resource.address])
} 