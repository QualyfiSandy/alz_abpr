param parSourceVnetName string
param parTargetVnetName string
param parTargetVnetId string

//PEERING
resource hubToCorePeer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${parSourceVnetName}/${parTargetVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: parTargetVnetId 
    }
  }
}

