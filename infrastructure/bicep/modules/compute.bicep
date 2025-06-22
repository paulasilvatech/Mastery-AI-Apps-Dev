// Compute module for Mastery AI Workshop
// Provides compute resources for modules 11-30

@description('Location for all resources')
param location string

@description('Environment name (dev, staging, prod)')
param environment string

@description('Module number (11-30)')
param moduleNumber int

@description('Suffix for resource names')
param suffix string

@description('Tags to apply to resources')
param tags object = {}

@description('Virtual network ID for AKS')
param virtualNetworkId string = ''

@description('Subnet ID for AKS')
param subnetId string = ''

@description('Log Analytics workspace ID')
param logAnalyticsWorkspaceId string

@description('Container Registry ID')
param containerRegistryId string = ''

// AKS Cluster (Modules 11+)
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-11-01' = if (moduleNumber >= 11) {
  name: 'aks-module${moduleNumber}-${environment}-${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: 'aks-${environment}-${suffix}'
    
    agentPoolProfiles: [
      {
        name: 'system'
        count: environment == 'prod' ? 3 : 1
        vmSize: environment == 'prod' ? 'Standard_D4s_v3' : 'Standard_B2s'
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: environment == 'prod' ? 5 : 3
        maxPods: 110
        osDiskSizeGB: 128
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: !empty(subnetId) ? subnetId : null
        enableNodePublicIP: false
      }
    ]
    
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
      loadBalancerSku: 'standard'
    }
    
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceId
        }
      }
      azurePolicy: {
        enabled: true
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
        }
      }
    }
    
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    
    apiServerAccessProfile: {
      enablePrivateCluster: environment == 'prod'
    }
    
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
    }
    
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      imageCleaner: {
        enabled: true
        intervalHours: 24
      }
    }
  }
  tags: tags
}

// User Node Pool for Applications (Modules 12+)
resource aksUserNodePool 'Microsoft.ContainerService/managedClusters/agentPools@2023-11-01' = if (moduleNumber >= 12) {
  parent: aksCluster
  name: 'user'
  properties: {
    count: environment == 'prod' ? 2 : 1
    vmSize: environment == 'prod' ? 'Standard_D2s_v3' : 'Standard_B2s'
    osType: 'Linux'
    mode: 'User'
    enableAutoScaling: true
    minCount: 0
    maxCount: environment == 'prod' ? 10 : 3
    maxPods: 110
    osDiskSizeGB: 128
    type: 'VirtualMachineScaleSets'
    vnetSubnetID: !empty(subnetId) ? subnetId : null
    enableNodePublicIP: false
    nodeLabels: {
      'workload': 'application'
    }
    nodeTaints: [
      'workload=application:NoSchedule'
    ]
  }
}

// Container Apps Environment (Modules 23+)
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = if (moduleNumber >= 23) {
  name: 'cae-module${moduleNumber}-${environment}-${suffix}'
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2022-10-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2022-10-01').primarySharedKey
      }
    }
    vnetConfiguration: !empty(subnetId) ? {
      infrastructureSubnetId: subnetId
      internal: false
    } : null
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
      {
        name: 'D4'
        workloadProfileType: 'D4'
        minimumCount: 0
        maximumCount: environment == 'prod' ? 10 : 3
      }
    ]
  }
  tags: tags
}

// Sample Container App (Module 24+)
resource sampleContainerApp 'Microsoft.App/containerApps@2023-05-01' = if (moduleNumber >= 24) {
  name: 'ca-sample-${environment}-${suffix}'
  location: location
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: [
        {
          name: 'registry-password'
          value: !empty(containerRegistryId) ? listCredentials(containerRegistryId, '2023-07-01').passwords[0].value : 'placeholder'
        }
      ]
      registries: !empty(containerRegistryId) ? [
        {
          server: !empty(containerRegistryId) ? reference(containerRegistryId, '2023-07-01').loginServer : 'mcr.microsoft.com'
          username: !empty(containerRegistryId) ? reference(containerRegistryId, '2023-07-01').adminUsername : 'admin'
          passwordSecretRef: 'registry-password'
        }
      ] : []
    }
    template: {
      containers: [
        {
          name: 'sample-app'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'ENVIRONMENT'
              value: environment
            }
            {
              name: 'MODULE_NUMBER'
              value: string(moduleNumber)
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: environment == 'prod' ? 10 : 3
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
    workloadProfileName: 'Consumption'
  }
  tags: tags
}

// Virtual Machine Scale Set (Modules 15+)
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-07-01' = if (moduleNumber >= 15) {
  name: 'vmss-module${moduleNumber}-${environment}'
  location: location
  sku: {
    name: environment == 'prod' ? 'Standard_D2s_v3' : 'Standard_B2s'
    capacity: environment == 'prod' ? 3 : 1
  }
  properties: {
    upgradePolicy: {
      mode: 'Rolling'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 20
        maxUnhealthyInstancePercent: 20
        maxUnhealthyUpgradedInstancePercent: 20
        pauseTimeBetweenBatches: 'PT0S'
      }
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'vm'
        adminUsername: 'azureuser'
        disablePasswordAuthentication: true
        linuxConfiguration: {
          ssh: {
            publicKeys: [
              {
                path: '/home/azureuser/.ssh/authorized_keys'
                keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...' // Replace with actual public key
              }
            ]
          }
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: {
          publisher: 'Canonical'
          offer: '0001-com-ubuntu-server-focal'
          sku: '20_04-lts-gen2'
          version: 'latest'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-config'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ip-config'
                  properties: {
                    subnet: {
                      id: !empty(subnetId) ? subnetId : resourceId('Microsoft.Network/virtualNetworks/subnets', 'vnet-default', 'subnet-default')
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: loadBalancer.properties.backendAddressPools[0].id
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'customScript'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              type: 'CustomScript'
              typeHandlerVersion: '2.1'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/vmss-ubuntu-web-ssl/install-apache.sh'
                ]
                commandToExecute: 'bash install-apache.sh'
              }
            }
          }
        ]
      }
    }
    orchestrationMode: 'Uniform'
  }
  tags: tags
}

// Load Balancer for VMSS
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-06-01' = if (moduleNumber >= 15) {
  name: 'lb-module${moduleNumber}-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backend'
      }
    ]
    loadBalancingRules: [
      {
        name: 'http'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb-module${moduleNumber}-${environment}', 'frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-module${moduleNumber}-${environment}', 'backend')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb-module${moduleNumber}-${environment}', 'http-probe')
          }
        }
      }
    ]
    probes: [
      {
        name: 'http-probe'
        properties: {
          protocol: 'Http'
          port: 80
          requestPath: '/'
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
  tags: tags
}

// Public IP for Load Balancer
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-06-01' = if (moduleNumber >= 15) {
  name: 'pip-lb-${environment}-${suffix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'workshop-${environment}-${suffix}'
    }
  }
  tags: tags
}

// Auto Scale Settings for VMSS
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (moduleNumber >= 15) {
  name: 'autoscale-vmss-${environment}'
  location: location
  properties: {
    profiles: [
      {
        name: 'default'
        capacity: {
          minimum: '1'
          maximum: environment == 'prod' ? '10' : '3'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'Microsoft.Compute/virtualMachineScaleSets'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'Microsoft.Compute/virtualMachineScaleSets'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: vmss.id
  }
  tags: tags
}

// Outputs
output aksClusterId string = moduleNumber >= 11 ? aksCluster.id : ''
output aksClusterName string = moduleNumber >= 11 ? aksCluster.name : ''
output aksClusterFqdn string = moduleNumber >= 11 ? aksCluster.properties.fqdn : ''
output aksClusterNodeResourceGroup string = moduleNumber >= 11 ? aksCluster.properties.nodeResourceGroup : ''

output containerAppsEnvironmentId string = moduleNumber >= 23 ? containerAppsEnvironment.id : ''
output containerAppsEnvironmentName string = moduleNumber >= 23 ? containerAppsEnvironment.name : ''
output containerAppsEnvironmentDomain string = moduleNumber >= 23 ? containerAppsEnvironment.properties.defaultDomain : ''

output sampleContainerAppId string = moduleNumber >= 24 ? sampleContainerApp.id : ''
output sampleContainerAppUrl string = moduleNumber >= 24 ? 'https://${sampleContainerApp.properties.configuration.ingress.fqdn}' : ''

output vmssId string = moduleNumber >= 15 ? vmss.id : ''
output vmssName string = moduleNumber >= 15 ? vmss.name : ''
output loadBalancerIp string = moduleNumber >= 15 ? publicIP.properties.ipAddress : ''
output loadBalancerFqdn string = moduleNumber >= 15 ? publicIP.properties.dnsSettings.fqdn : ''

// Compute resources summary
output computeResourcesDeployed array = [
  moduleNumber >= 11 ? 'AKS Cluster' : null
  moduleNumber >= 12 ? 'AKS User Node Pool' : null
  moduleNumber >= 15 ? 'Virtual Machine Scale Set' : null
  moduleNumber >= 15 ? 'Load Balancer' : null
  moduleNumber >= 23 ? 'Container Apps Environment' : null
  moduleNumber >= 24 ? 'Sample Container App' : null
]
