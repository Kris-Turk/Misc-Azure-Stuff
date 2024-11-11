param virtualNetworkName string
param addressSpaces array
param subnets array
param bastionSubnetAddressSpace string
// param dnsServers array
param location string = resourceGroup().location
param peeredvNet_name string
param peeredvNet_rg string
param peeredvnet_sub string
param firewallPrivateIP string


param subid string //current subscription

resource flowLogsStorageAccount_r 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'flowlogs${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: {}
}

resource virtualNetwork_r 'Microsoft.Network/VirtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  dependsOn:[
    routeTable
    nsg
  ]
  tags: {}
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: [for subnet in subnets: {
      name:subnet.name
      properties:{
        addressPrefix: subnet.subnetPrefix
        networkSecurityGroup: subnet.nsg == 'false' ? null : {
          id: resourceId('Microsoft.Network/networkSecurityGroups', 'nsg-${subnet.name}')
        }
        routeTable: subnet.rt == 'false' ? null : {
          id: resourceId('Microsoft.Network/routeTables', 'rt-${subnet.name}')
        }
        privateLinkServiceNetworkPolicies: subnet.function == 'lb' ? 'Disabled' : 'Enabled'
        delegations: subnet.function == 'smtp' ? [
          {
            name: 'ACIDelegationService'
            properties: {
              serviceName: 'Microsoft.ContainerInstance/containerGroups'
            }
          }
        ] :[
          
        ]
      }
    }]
    // dhcpOptions: {
    //   dnsServers: dnsServers
    // }

  }  
}

resource routeTable 'Microsoft.Network/routeTables@2021-03-01' = [for subnet in subnets: if(subnet.rt == 'true') {
  name: 'rt-${subnet.name}'
  tags: resourceGroup().tags
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'Default'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallPrivateIP
        }
      }
      {
        name: 'IntraVnet'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: addressSpaces[0]
          nextHopIpAddress: firewallPrivateIP
        }
      }
    ]
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = [for subnet in subnets: if(subnet.nsg == 'true'){
  name:'nsg-${subnet.name}'
  tags: resourceGroup().tags
  location: location
  properties:{
    securityRules:[
      {
        name: 'AllowBastionInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: bastionSubnetAddressSpace
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: [
            '22'
            '3389'
          ]
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowLocalNetwork'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: addressSpaces[0]
          destinationPortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }      
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 400
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRange: '*'
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }       
      {
        name: 'AllowICMPv4'
          properties: {
          protocol: 'Icmp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 124
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
           sourceAddressPrefixes: addressSpaces
           destinationAddressPrefixes: []
         }
        }
        subnet.function == 'iis' ? {
          name: 'AllowWebTrafficInbound'
            properties: {
            protocol: '*'
            sourcePortRange: '*'
            sourceAddressPrefix: 'AzureLoadBalancer'
            destinationAddressPrefix: subnet.subnetPrefix
            access: 'Allow'
            priority: 350
            direction: 'Inbound'
            sourcePortRanges: []
            destinationPortRanges: [
              '80'
              '443'
            ]             
             destinationAddressPrefixes: []
           }
          } : {
            name: 'DenyInternetWebTrafficInbound'
              properties: {
              protocol: '*'
              sourcePortRange: '*'
              sourceAddressPrefix: 'Internet'
              destinationAddressPrefix: subnet.subnetPrefix
              access: 'Deny'
              priority: 410
              direction: 'Inbound'
              sourcePortRanges: []
              destinationPortRanges: [
                '80'
                '443'
              ]             
               destinationAddressPrefixes: []
             }
            }     
    ]
  }
}
]

resource hubVnet 'Microsoft.Network/VirtualNetworks@2020-06-01' existing = {
  name: peeredvNet_name
  scope: resourceGroup(peeredvnet_sub,peeredvNet_rg)
}

resource vNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  parent: virtualNetwork_r
  name: '${virtualNetworkName}-${peeredvNet_name}'  
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
    remoteAddressSpace: hubVnet.properties.addressSpace         
  }
}

// create virtual network peering for remote vnet
module remotepeering './peering.bicep' = {
  name: '${virtualNetworkName}-remotepeering'
  scope: resourceGroup(peeredvnet_sub, peeredvNet_rg)
  dependsOn: [
    virtualNetwork_r
  ]
  params:{
    localVnetName:peeredvNet_name
    remoteVnetName: virtualNetworkName
    remoteVnetRg:resourceGroup().name
    remoteVnetsub:subid
  }
}

resource internalLoadbalancer 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: 'ilb-${virtualNetworkName}'
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  location: location
  tags: resourceGroup().tags
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe-ilb-${virtualNetworkName}'
        zones: [
          '1'
          '2'
          '3'
        ]
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork_r.properties.subnets[2].id
          }
        }
      }
    ]
  }
}

resource privatelinkService 'Microsoft.Network/privateLinkServices@2021-02-01'= {
  name: 'pl-${subnets[2].name}'
  location: location
  tags: resourceGroup().tags
  properties: {
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: internalLoadbalancer.properties.frontendIPConfigurations[0].id
      }
    ]
    ipConfigurations: [
      {
        name: 'ipconfig-pl-${subnets[2].name}'
        properties: {
          primary: true
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: virtualNetwork_r.properties.subnets[2].id
          }
        }
      }
    ]
  }
}

output virtualNetworkId string = virtualNetwork_r.id
