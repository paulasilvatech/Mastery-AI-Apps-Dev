# Storage Module

This module provisions storage solutions for the Mastery AI Workshop.

## Resources Created

- Storage Accounts
- Blob Containers
- File Shares
- Queue Storage
- Table Storage
- Azure SQL Database
- Redis Cache

## Usage

```hcl
module "storage" {
  source = "../../modules/storage"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  project_name       = var.project_name
  
  storage_config = {
    account_tier             = "Standard"
    account_replication_type = "LRS"
    enable_https_traffic_only = true
    min_tls_version          = "TLS1_2"
    
    containers = [
      {
        name                  = "data"
        container_access_type = "private"
      },
      {
        name                  = "models"
        container_access_type = "private"
      },
      {
        name                  = "logs"
        container_access_type = "private"
      }
    ]
    
    file_shares = [
      {
        name  = "config"
        quota = 5120  # 5TB
      }
    ]
    
    queues = ["tasks", "events", "notifications"]
    tables = ["metadata", "sessions"]
  }
  
  sql_database_config = {
    edition    = "Basic"
    size       = "Basic"
    max_size   = "2GB"
    collation  = "SQL_Latin1_General_CP1_CI_AS"
  }
  
  redis_config = {
    family   = "C"
    capacity = 0  # Basic tier
    sku_name = "Basic"
    enable_non_ssl_port = false
  }
  
  enable_data_protection = true
  enable_encryption      = true
  
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
| storage_config | Storage account configuration | object | n/a | yes |
| sql_database_config | SQL database configuration | object | {} | no |
| redis_config | Redis cache configuration | object | {} | no |
| enable_data_protection | Enable backup and soft delete | bool | true | no |
| enable_encryption | Enable encryption at rest | bool | true | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| storage_account_name | Storage account name |
| storage_account_id | Storage account resource ID |
| storage_account_key | Storage account primary key |
| blob_endpoint | Blob storage endpoint |
| file_endpoint | File storage endpoint |
| queue_endpoint | Queue storage endpoint |
| table_endpoint | Table storage endpoint |
| container_ids | Map of container resource IDs |
| sql_server_fqdn | SQL server FQDN |
| sql_database_id | SQL database resource ID |
| redis_hostname | Redis cache hostname |
| redis_port | Redis cache port |
| redis_primary_key | Redis cache primary key |

## Storage Features

### Blob Storage
- **Hot/Cool/Archive Tiers**: Optimize costs based on access patterns
- **Lifecycle Management**: Automatic tier transitions
- **Immutable Storage**: WORM (Write Once Read Many) support
- **Versioning**: Keep previous versions of blobs
- **Soft Delete**: Recover accidentally deleted data

### File Storage
- **SMB 3.0 Protocol**: Windows and Linux compatible
- **Azure File Sync**: Hybrid cloud file sharing
- **Snapshots**: Point-in-time backups
- **Large File Shares**: Up to 100 TiB

### Queue Storage
- **Reliable Messaging**: At-least-once delivery
- **Visibility Timeout**: Message processing control
- **Poison Message Handling**: Automatic retry logic
- **Batch Operations**: Process multiple messages

### Table Storage
- **NoSQL Key-Value Store**: Fast lookups
- **Partition and Row Keys**: Efficient querying
- **OData Protocol**: RESTful API
- **Secondary Indexes**: Query flexibility

## Security Features

1. **Encryption at Rest**: All data encrypted using Microsoft-managed keys
2. **Encryption in Transit**: TLS 1.2 minimum
3. **Firewall Rules**: IP-based access restrictions
4. **Private Endpoints**: Network isolation
5. **Shared Access Signatures**: Granular access control
6. **Azure AD Integration**: Identity-based access

## High Availability

### Storage Account
- **LRS**: 3 copies within a single datacenter
- **ZRS**: 3 copies across availability zones
- **GRS**: 6 copies across two regions
- **GZRS**: Combination of ZRS and GRS

### SQL Database
- **Automatic Backups**: Point-in-time restore
- **Geo-Replication**: Read replicas in other regions
- **Failover Groups**: Automatic failover

### Redis Cache
- **Persistence**: RDB and AOF options
- **Replication**: Master-slave configuration
- **Clustering**: Scale-out support

## Cost Optimization

1. **Lifecycle Policies**: Move data to cooler tiers
2. **Reserved Capacity**: Up to 72% savings
3. **Serverless SQL**: Pay-per-query pricing
4. **Cache Eviction**: Manage memory efficiently
5. **Compression**: Reduce storage requirements
