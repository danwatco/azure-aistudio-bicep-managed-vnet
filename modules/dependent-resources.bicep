// Creates Azure dependent resources for Azure AI studio

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('AI services name')
param aiServicesName string

@description('Application Insights resource name')
param applicationInsightsName string

@description('Container registry name')
param containerRegistryName string

@description('The name of the Key Vault')
param keyvaultName string

param privateDnsVnetId string
param privateEndpointSubnetId string

var containerRegistryNameCleaned = replace(containerRegistryName, '-', '')



// resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
//   name: applicationInsightsName
//   location: location
//   tags: tags
//   kind: 'web'
//   properties: {
//     Application_Type: 'web'
//     DisableIpMasking: false
//     DisableLocalAuth: false
//     Flow_Type: 'Bluefield'
//     ForceCustomerStorageForProfiler: false
//     ImmediatePurgeDataOn30Days: true
//     IngestionMode: 'ApplicationInsights'
//     publicNetworkAccessForIngestion: 'Enabled'
//     publicNetworkAccessForQuery: 'Disabled'
//     Request_Source: 'rest'
//   }
// }

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryNameCleaned
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
    }
    policies: {
      quarantinePolicy: {
        status: 'enabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: 'Disabled'
    zoneRedundancy: 'Disabled'
  }
}

// module acrPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
//   name: 'acrPrivateDnsZoneDeployment'
//   params: {
//     // Required parameters
//     name: 'privatelink.azurecr.io'
//     virtualNetworkLinks: [
//       {
//         registrationEnabled: false
//         virtualNetworkResourceId: privateDnsVnetId
//       }
//     ]
//   }
// }

// module acrPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
//   name: 'acrPrivateEndpointDeployment'
//   params: {
//     name: 'pe-${containerRegistryNameCleaned}'
//     subnetResourceId: privateEndpointSubnetId
//     privateDnsZoneResourceIds: [
//       acrPrivateDnsZone.outputs.resourceId
//     ]
//     privateLinkServiceConnections: [
//       {
//         name: 'acr'
//         properties: {
//           groupIds: ['registry']
//           privateLinkServiceId: containerRegistry.id
//         }
//       }
//     ]
//   }
// }

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyvaultName
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    sku: {
      family: 'A'
      name: 'standard'
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
    publicNetworkAccess: 'Disabled'
  }
}

module keyvaultPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'keyvaultPrivateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'privatelink.vaultcore.azure.net'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module keyvaultPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  name: 'keyvaultPrivateEndpointDeployment'
  params: {
    name: 'pe-${containerRegistryNameCleaned}'
    subnetResourceId: privateEndpointSubnetId
    privateDnsZoneResourceIds: [
      keyvaultPrivateDnsZone.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
        name: 'keyvault'
        properties: {
          groupIds: ['vault']
          privateLinkServiceId: keyVault.id
        }
      }
    ]
  }
}

@description('Name of the storage account')
param storageName string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])

@description('Storage SKU')
param storageSkuName string = 'Standard_LRS'

var storageNameCleaned = replace(storageName, '-', '')

resource aiServices 'Microsoft.CognitiveServices/accounts@2021-10-01' = {
  name: aiServicesName
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'AIServices' // or 'OpenAI'
  properties: {
    apiProperties: {
      statisticsEnabled: false
    }
    publicNetworkAccess: 'Disabled'
    customSubDomainName: aiServicesName
  }
}

module aiservicesPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'aiservicesPrivateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'privatelink.cognitiveservices.azure.com'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module aiservicesPrivateDnsZone2 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'aiservicesPrivateDnsZoneDeployment2'
  params: {
    // Required parameters
    name: 'privatelink.openai.azure.com'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module aiservicesPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  name: 'aiservicesPrivateEndpointDeployment'
  params: {
    name: 'pe-${aiServicesName}-aiservices'
    subnetResourceId: privateEndpointSubnetId
    privateDnsZoneResourceIds: [
      aiservicesPrivateDnsZone.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
        name: 'aiservices'
        properties: {
          groupIds: ['account']
          privateLinkServiceId: aiServices.id
        }
      }
    ]
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageNameCleaned
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
  }
}

module blobPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'blobPrivateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'privatelink.blob.core.windows.net'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module blobPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  name: 'blobPrivateEndpointDeployment'
  params: {
    name: 'pe-${storageNameCleaned}-blob'
    subnetResourceId: privateEndpointSubnetId
    privateDnsZoneResourceIds: [
      blobPrivateDnsZone.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
        name: 'blob'
        properties: {
          groupIds: ['blob']
          privateLinkServiceId: storage.id
        }
      }
    ]
  }
}

module filePrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'filePrivateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'privatelink.file.core.windows.net'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module filePrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  name: 'filePrivateEndpointDeployment'
  params: {
    name: 'pe-${storageNameCleaned}-file'
    subnetResourceId: privateEndpointSubnetId
    privateDnsZoneResourceIds: [
      filePrivateDnsZone.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
        name: 'file'
        properties: {
          groupIds: ['file']
          privateLinkServiceId: storage.id
        }
      }
    ]
  }
}

output aiservicesID string = aiServices.id
output aiservicesTarget string = aiServices.properties.endpoint
output storageId string = storage.id
output keyvaultId string = keyVault.id
output containerRegistryId string = containerRegistry.id
// output applicationInsightsId string = applicationInsights.id
