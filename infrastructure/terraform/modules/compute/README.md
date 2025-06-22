# Compute Module

This module provisions compute resources for the Mastery AI Workshop.

## Resources Created

- Azure Kubernetes Service (AKS)
- Azure Functions
- Azure Container Instances
- App Service Plans

## Usage

```hcl
module "compute" {
  source = "../../modules/compute"
  
  resource_group_name = azurerm_resource_group.main.name
  location           = azurerm_resource_group.main.location
  environment        = var.environment
  project_name       = var.project_name
  
  aks_config = {
    node_count           = 3
    node_size           = "Standard_D2_v2"
    kubernetes_version  = "1.28.3"
    enable_auto_scaling = true
    min_node_count      = 1
    max_node_count      = 5
  }
  
  function_app_config = {
    runtime_version = "4"
    runtime_stack   = "python"
    python_version  = "3.11"
    always_on       = false
    sku_tier        = "Dynamic"
    sku_size        = "Y1"
  }
  
  container_instances = [
    {
      name   = "agent-orchestrator"
      image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
      cpu    = "1"
      memory = "2"
      port   = 80
    }
  ]
  
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
| aks_config | AKS configuration | object | n/a | yes |
| function_app_config | Function app configuration | object | n/a | yes |
| container_instances | Container instances to create | list(object) | [] | no |
| tags | Resource tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| aks_cluster_name | AKS cluster name |
| aks_cluster_id | AKS cluster resource ID |
| aks_kube_config | AKS kubeconfig |
| function_app_name | Function app name |
| function_app_default_hostname | Function app hostname |
| function_app_id | Function app resource ID |
| app_service_plan_id | App service plan ID |
| container_instance_ids | Container instance IDs |

## AKS Features

- **Auto-scaling**: Automatically adjusts node count based on load
- **Azure Monitor**: Integrated monitoring and diagnostics
- **Network Policy**: Calico network policy support
- **Azure Policy**: Built-in security policies
- **Managed Identity**: System-assigned identity for Azure resource access

## Function App Features

- **Consumption Plan**: Pay-per-execution pricing
- **Durable Functions**: Stateful function orchestration
- **Application Insights**: Built-in monitoring
- **Managed Identity**: Secure access to Azure resources
- **VNET Integration**: Optional private networking

## Security Considerations

1. **Network Security**: Network policies and NSGs configured
2. **Identity**: Managed identities for secure authentication
3. **RBAC**: Role-based access control enabled
4. **Private Endpoints**: Optional private connectivity
5. **Key Vault Integration**: Secure secret management
