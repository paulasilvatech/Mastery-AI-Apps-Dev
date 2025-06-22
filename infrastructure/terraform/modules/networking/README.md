# Networking Module

This module creates and manages network infrastructure for the Mastery AI Workshop.

## Resources Created

- Virtual Networks (VNet)
- Subnets with service endpoints
- Network Security Groups (NSGs)
- Application Gateway
- Private DNS Zones
- Private Endpoints

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  project_name       = var.project_name
  
  vnet_config = {
    address_space = ["10.0.0.0/16"]
    dns_servers   = []
    
    subnets = {
      default = {
        address_prefixes     = ["10.0.1.0/24"]
        service_endpoints    = ["Microsoft.Storage", "Microsoft.Sql"]
        delegation          = null
      }
      aks = {
        address_prefixes     = ["10.0.2.0/23"]
        service_endpoints    = ["Microsoft.ContainerRegistry"]
        delegation          = null
      }
      functions = {
        address_prefixes     = ["10.0.4.0/24"]
        service_endpoints    = ["Microsoft.Web"]
        delegation = {
          name = "Microsoft.Web/serverFarms"
          service_delegation = {
            name = "Microsoft.Web/serverFarms"
            actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
          }
        }
      }
      private_endpoints = {
        address_prefixes     = ["10.0.5.0/24"]
        service_endpoints    = []
        delegation          = null
      }
    }
  }
  
  nsg_rules = {
    AllowHTTPS = {
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range         = "*"
      destination_port_range    = "443"
      source_address_prefix     = "*"
      destination_address_prefix = "*"
    }
  }
  
  enable_ddos_protection   = false
  enable_private_endpoints = true
  
  tags = var.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| project_name | Project name | string | n/a | yes |
| vnet_config | Virtual network configuration | object | n/a | yes |
| nsg_rules | Network security group rules | map(object) | {} | no |
| enable_ddos_protection | Enable DDoS protection | bool | false | no |
| enable_private_endpoints | Enable private endpoints | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vnet_id | Virtual network ID |
| vnet_name | Virtual network name |
| subnet_ids | Map of subnet IDs |
| nsg_id | Network security group ID |
| private_dns_zone_ids | Map of private DNS zone IDs |
| application_gateway_id | Application gateway ID (if created) |

## Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Virtual Network                        │
│                    10.0.0.0/16                           │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │  Default Subnet │  │   AKS Subnet    │              │
│  │  10.0.1.0/24    │  │  10.0.2.0/23    │              │
│  └─────────────────┘  └─────────────────┘              │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │Functions Subnet │  │Private Endpoints│              │
│  │  10.0.4.0/24    │  │  10.0.5.0/24    │              │
│  └─────────────────┘  └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## Security Features

### Network Security Groups
- Default deny all inbound traffic
- Allow rules for specific services
- Outbound internet access controlled
- Application security groups support

### Service Endpoints
- Direct connectivity to Azure services
- Traffic stays on Azure backbone
- Reduced latency and improved security

### Private Endpoints
- Private IP addresses for Azure services
- Eliminates public internet exposure
- DNS integration for seamless connectivity

## Best Practices

1. **Subnet Sizing**: Plan for growth with appropriate CIDR blocks
2. **NSG Rules**: Follow least privilege principle
3. **Service Endpoints**: Enable only for required services
4. **DNS Configuration**: Use Azure Private DNS zones
5. **Network Isolation**: Separate workloads into different subnets
