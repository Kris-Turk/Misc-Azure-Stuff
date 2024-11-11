param localVnetName string
param remoteVnetName string
param remoteVnetRg string
param remoteVnetsub string

resource remotevnet 'Microsoft.Network/VirtualNetworks@2020-06-01' existing = {
  name: remoteVnetName
  scope: resourceGroup(remoteVnetsub,remoteVnetRg)
}

resource localVnet  'Microsoft.Network/VirtualNetworks@2020-06-01' existing = {
  name: localVnetName
}

// create vnet peer
resource peer 'microsoft.network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: localVnet
  name: '${localVnetName}-${remoteVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    remoteVirtualNetwork: {
      id: remotevnet.id
    }
  }
}
