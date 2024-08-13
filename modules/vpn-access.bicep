param vnetGatewayName string
param vpnSku string = 'VpnGw1'

param vnetResourceId string
param subnetName string

module vpn 'br/public:avm/res/network/virtual-network-gateway:0.2.0' = {
  name: '${vnetGatewayName}-deployment'
  params: {
    name: vnetGatewayName
    gatewayType: 'Vpn'
    skuName: vpnSku
    vNetResourceId: vnetResourceId
    activeActive: false
    enableBgp: false
  }
}


module dnsResolver 'br/public:avm/res/network/dns-resolver:0.4.0' = {
  name: '${vnetGatewayName}-dns-resolver-deployment'
  params: {
    name: '${vnetGatewayName}-dns-resolver'
    virtualNetworkResourceId: vnetResourceId
    inboundEndpoints: [
      {
        name: 'inbound-endpoint-01'
        subnetResourceId: resourceId(vnetResourceId, 'Microsoft.Network/virtualNetworks/subnets', subnetName)
      }
    ]
  }
}


module clientConnection 'br/public:avm/res/network/connection:0.1.2' = {
  name: '${vnetGatewayName}-client-connection-deployment'
  params: {
    name: '${vnetGatewayName}-client-connection'
    connectionType: 'VPNClient'
    virtualNetworkGateway1: {id: vpn.outputs.resourceId}
  }
}
