param vNetName string

param location string = resourceGroup().location

param subnets array = [{
  name: 'default'
  addressPrefix: '10.0.0.0/24'
  delegations: [{
    name: 'dnsDel'
    properties: {
      serviceName: 'Microsoft.Network/dnsResolvers'
    }
  }]
}
{
  name: 'subnet-pe'
  addressPrefix: '10.0.1.0/24'
  privateEndpointNetworkPolicies: 'Disabled'
}
{
  name: 'AzureBastionSubnet'
  addressPrefix: '10.0.2.0/24'
}
{
  name: 'GatewaySubnet'
  addressPrefix: '10.0.3.0/24'
}
]

param addressPrefixes array = ['10.0.0.0/16']


module vnet 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: vNetName
  params: {
    addressPrefixes: addressPrefixes
    name: vNetName
    location: location
    subnets: subnets
    dnsServers: ['10.0.0.4', '168.63.129.16']
    
  }
}


output vnetResourceId string = vnet.outputs.resourceId
output defaultSubnetResourceId string = vnet.outputs.subnetResourceIds[0]
output peSubnetResourceId string = vnet.outputs.subnetResourceIds[1]

