// Execute this main file to depoy Azure AI studio resources in the basic security configuraiton

// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param aiHubName string = 'demo'

@description('Friendly name for your Azure AI resource')
param aiHubFriendlyName string = 'Demo AI resource'

@description('Description of your Azure AI resource dispayed in AI studio')
param aiHubDescription string = 'This is an example AI resource for use in Azure AI Studio.'

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('Name of the VM to use for JumpBox')
param virtualMachineName string = 'vm-aistudio-lab'

@description('Name of Azure Bastion for VM Access')
param bastionName string = 'ai-bastion'

@description('Password for VM access')
@secure()
param vmPassword string

// Variables
var name = toLower('${aiHubName}')

// Create a short, unique suffix, that will be unique to each resource group
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

// User vnet for connections
module userVnet 'modules/support-vnet.bicep' = {
  name: 'suppport-vnet-${name}-${uniqueSuffix}-deployment'
  params: {
    vNetName: 'vnet-${name}-${uniqueSuffix}'
  }
}


// Dependent resources for the Azure Machine Learning workspace
module aiDependencies 'modules/dependent-resources.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    storageName: 'st${name}${uniqueSuffix}'
    keyvaultName: 'kv-${name}-${uniqueSuffix}'
    applicationInsightsName: 'appi-${name}-${uniqueSuffix}'
    containerRegistryName: 'cr${name}${uniqueSuffix}'
    aiServicesName: 'ais${name}${uniqueSuffix}'
    privateDnsVnetId: userVnet.outputs.vnetResourceId
    privateEndpointSubnetId: userVnet.outputs.peSubnetResourceId
    tags: tags
  }
}

module aiHub 'modules/ai-hub.bicep' = {
  name: 'ai-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    aiHubName: 'aih-${name}-${uniqueSuffix}'
    aiHubFriendlyName: aiHubFriendlyName
    aiHubDescription: aiHubDescription
    location: location
    tags: tags
    privateDnsVnetId: userVnet.outputs.vnetResourceId
    privateEndpointSubnetId: userVnet.outputs.peSubnetResourceId
    // dependent resources
    aiServicesId: aiDependencies.outputs.aiservicesID
    aiServicesTarget: aiDependencies.outputs.aiservicesTarget
    // applicationInsightsId: aiDependencies.outputs.applicationInsightsId
    containerRegistryId: aiDependencies.outputs.containerRegistryId
    keyVaultId: aiDependencies.outputs.keyvaultId
    storageAccountId: aiDependencies.outputs.storageId
  }
}


module vm 'modules/access-vm.bicep' = {
  name: 'access-vm-${name}-${uniqueSuffix}-deployment'
  params: {
    bastionName: bastionName
    subnetId: userVnet.outputs.defaultSubnetResourceId
    vmName: virtualMachineName
    vnetResourceId: userVnet.outputs.vnetResourceId
    adminPassword: vmPassword
  }
}
