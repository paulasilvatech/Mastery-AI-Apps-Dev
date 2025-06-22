# Azure AI Services Module

This module provisions Azure AI services for the workshop.

## Resources Created

- Azure OpenAI Service
- Azure AI Search
- Cosmos DB with vector search support
- Application Insights

## Usage

```hcl
module "ai_services" {
  source = "../../modules/ai-services"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  module_number      = var.module_number
  
  openai_config = {
    sku_name = "S0"
    deployments = [
      {
        name       = "gpt-4"
        model_name = "gpt-4"
        version    = "0613"
        capacity   = 10
      },
      {
        name       = "embedding"
        model_name = "text-embedding-ada-002"
        version    = "2"
        capacity   = 10
      }
    ]
  }
  
  search_config = {
    sku        = "standard"
    replica_count = 1
    partition_count = 1
  }
  
  cosmosdb_config = {
    offer_type = "Standard"
    kind       = "GlobalDocumentDB"
    consistency_level = "Session"
    enable_vector_search = true
  }
  
  tags = var.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| resource_group_name | Name of the resource group | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| module_number | Workshop module number | string | n/a | yes |
| openai_config | OpenAI service configuration | object | n/a | yes |
| search_config | AI Search configuration | object | n/a | yes |
| cosmosdb_config | Cosmos DB configuration | object | n/a | yes |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| openai_endpoint | OpenAI service endpoint |
| openai_key | OpenAI service key |
| search_endpoint | AI Search endpoint |
| search_key | AI Search admin key |
| cosmosdb_endpoint | Cosmos DB endpoint |
| cosmosdb_key | Cosmos DB primary key |
| app_insights_connection_string | Application Insights connection string |
