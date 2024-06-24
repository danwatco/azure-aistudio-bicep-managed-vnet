// Creates an Azure AI resource with proxied endpoints for the Azure AI services provider

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('AI hub name')
param aiHubName string

@description('AI hub display name')
param aiHubFriendlyName string = aiHubName

@description('AI hub description')
param aiHubDescription string

// @description('Resource ID of the application insights resource for storing diagnostics logs')
// param applicationInsightsId string

@description('Resource ID of the container registry resource for storing docker images')
param containerRegistryId string

@description('Resource ID of the key vault resource for storing connection strings')
param keyVaultId string

@description('Resource ID of the storage account resource for storing experimentation outputs')
param storageAccountId string

@description('Resource ID of the AI Services resource')
param aiServicesId string

@description('Resource ID of the AI Services endpoint')
param aiServicesTarget string

param privateDnsVnetId string
param privateEndpointSubnetId string


resource aiHub 'Microsoft.MachineLearningServices/workspaces@2023-08-01-preview' = {
  name: aiHubName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // organization
    friendlyName: aiHubFriendlyName
    description: aiHubDescription
    publicNetworkAccess: 'Disabled'
    managedNetwork: {
      isolationMode: 'AllowInternetOutbound'
      outboundRules: {
        'openai' : {
          type: 'PrivateEndpoint'
          destination: {
            serviceResourceId: aiServicesId
            subresourceTarget: 'account'
          }
        }
      }
    }
    // dependent resources
    keyVault: keyVaultId
    storageAccount: storageAccountId
    containerRegistry: containerRegistryId
  }
  kind: 'hub'

  resource aiServicesConnection 'connections@2024-01-01-preview' = {
    name: '${aiHubName}-connection-AzureOpenAI'
    properties: {
      category: 'AzureOpenAI'
      target: aiServicesTarget
      authType: 'ApiKey'
      isSharedToAll: true
      credentials: {
        key: '${listKeys(aiServicesId, '2021-10-01').key1}'
      }
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServicesId
      }
    }
  }
}

module aihubPrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'aihubPrivateDnsZoneDeployment'
  params: {
    // Required parameters
    name: 'privatelink.api.azureml.ms'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module aihubPrivateDnsZone2 'br/public:avm/res/network/private-dns-zone:0.3.0' = {
  name: 'aihubPrivateDnsZoneDeployment2'
  params: {
    // Required parameters
    name: 'privatelink.notebooks.azure.net'
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: privateDnsVnetId
      }
    ]
  }
}

module aihubPrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.4.1' = {
  name: 'aihubPrivateEndpointDeployment'
  params: {
    name: 'pe-${aiHubName}'
    subnetResourceId: privateEndpointSubnetId
    privateDnsZoneResourceIds: [
      aihubPrivateDnsZone.outputs.resourceId
      aihubPrivateDnsZone2.outputs.resourceId
    ]
    privateLinkServiceConnections: [
      {
        name: 'aihub'
        properties: {
          groupIds: ['amlworkspace']
          privateLinkServiceId: aiHub.id
        }
      }
    ]
  }
}

output aiHubID string = aiHub.id
