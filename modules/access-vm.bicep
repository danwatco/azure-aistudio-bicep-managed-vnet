param vmName string
param location string = resourceGroup().location

param subnetId string

param bastionName string
param bastionEnabled bool = true
param vnetResourceId string

param adminUsername string = 'azureuser'

@secure()
param adminPassword string


param vmSize string = 'Standard_DS2_v2'


module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.5.1' = {
  name: 'virtualMachineDeployment'
  params: {
    // Required parameters
    adminUsername: adminUsername
    zone: 0
    imageReference: {
      offer: 'WindowsServer'
      publisher: 'MicrosoftWindowsServer'
      sku: '2022-datacenter-azure-edition'
      version: 'latest'
    }
    name: vmName
    encryptionAtHost: false
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            subnetResourceId: subnetId
            zones: []
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Windows'
    vmSize: vmSize
    // Non-required parameters
    adminPassword: adminPassword
    location: location
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.2.1' = if (bastionEnabled) {
  name: 'bastionHostDeployment'
  params: {
    name: bastionName
    virtualNetworkResourceId: vnetResourceId
    skuName: 'Basic'
  }
}
