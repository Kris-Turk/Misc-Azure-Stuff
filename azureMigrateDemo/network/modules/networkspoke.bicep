param virtualNetworkName string
param addressSpaces array
param subnets array
param bastionSubnetAddressSpace string
// param dnsServers array
param corpAddressRanges array
param location string = resourceGroup().location
param peeredvNet_name string
param peeredvNet_rg string
param peeredvnet_sub string
param firewallPrivateIP string

param subid string //current subscription

resource virtualNetworkName_resource 'Microsoft.Network/VirtualNetworks@2020-06-01' = {
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
          priority: 4094
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
          priority: 150
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
           sourceAddressPrefixes: corpAddressRanges
           destinationAddressPrefixes: []
         }
        }
        {
          name: 'AllowAzMigrate'
            properties: {
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationAddressPrefix: '*'
            access: 'Allow'
            priority: 125
            direction: 'Inbound'
            sourcePortRanges: [
              '443'
              '9443'
            ]
            destinationPortRanges: []
             sourceAddressPrefixes: corpAddressRanges
             destinationAddressPrefixes: []
           }
          }
          {
            name: 'AllowSMB'
              properties: {
              protocol: 'Tcp'
              sourcePortRange: '*'
              destinationPortRange: '445'
              destinationAddressPrefix: '*'
              access: 'Allow'
              priority: 126
              direction: 'Inbound'
              sourcePortRanges: []
              destinationPortRanges: []
               sourceAddressPrefixes: corpAddressRanges
               destinationAddressPrefixes: []
             }
            }
    ]
  }
}]

resource hubVnet 'Microsoft.Network/VirtualNetworks@2020-06-01' existing = {
  name: peeredvNet_name
  scope: resourceGroup(peeredvnet_sub,peeredvNet_rg)
}

resource vNetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-03-01' = {
  parent: virtualNetworkName_resource
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
  name: 'remotepeering'
  scope: resourceGroup(peeredvnet_sub, peeredvNet_rg)
  dependsOn: [
    virtualNetworkName_resource
  ]
  params:{
    localVnetName:peeredvNet_name
    remoteVnetName: virtualNetworkName
    remoteVnetRg:resourceGroup().name
    remoteVnetsub:subid
  }
}

output virtualNetworkId string = virtualNetworkName_resource.id
