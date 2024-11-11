param virtualNetworkName string
param addressSpaces array

param subnet0_name string
param subnet0_addressRange string
param subnet1_name string
param subnet1_addressRange string
param subnet2_name string
param subnet2_addressRange string
param bastionSubnetName string
param bastionName string
param bastionSubnetAddressSpace string

// param lbName string

param location string = resourceGroup().location

var publicIpAddressForBastion  = 'pip-${bastionName}'
// var nsg0name = 'nsg-${subnet0_name}'
// var nsg1name = 'nsg-${subnet1_name}'
var nsg2name = 'nsg-${subnet2_name}'
var nsgBastion = 'nsg-${bastionSubnetName}'


resource virtualNetworkName_resource 'Microsoft.Network/VirtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  tags: resourceGroup().tags
  properties: {
    addressSpace: {
      addressPrefixes: addressSpaces
    }
    subnets: [     
      {
        name: subnet0_name
        properties: {
          addressPrefix: subnet0_addressRange
          // networkSecurityGroup: {
          //   id: nsg0_resource.id
          // }
        }
      } 
      {
        name: subnet1_name
        properties: {
          addressPrefix: subnet1_addressRange
          // networkSecurityGroup: {
          //   id: nsg1_resource.id
          // }          
        }
      }
      {
        name: subnet2_name
        properties: {
          addressPrefix: subnet2_addressRange
          networkSecurityGroup:{
            id: nsg2_resource.id
          }
        }
      }      
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetAddressSpace
          networkSecurityGroup:{
            id: nsgBastion_resource.id
          }
        }
      }
    ]
  }
}



resource publicIpAddressForBastion_resource 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: publicIpAddressForBastion
  tags: resourceGroup().tags
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionName_r 'Microsoft.Network/bastionHosts@2023-11-01' = {
  name: bastionName
  tags: resourceGroup().tags
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    enableShareableLink: true
    scaleUnits: 2
    enableTunneling: true
    enableIpConnect: true
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', '${virtualNetworkName_resource.name}', 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', '${publicIpAddressForBastion_resource.name}')
          }
        }
      }
    ]
  }
}

// resource nsg0_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
//   name:nsg0name
//   tags: resourceGroup().tags
//   location: location
//   properties:{
//     securityRules:[
//       {
//         name: 'AllowBastionInbound'
//         properties: {
//           protocol: '*'
//           sourcePortRange: '*'
//           sourceAddressPrefix: bastionSubnetAddressSpace
//           destinationAddressPrefix: '*'
//           access: 'Allow'
//           priority: 100
//           direction: 'Inbound'
//           sourcePortRanges: []
//           destinationPortRanges: [
//             '22'
//             '3389'
//           ]
//           sourceAddressPrefixes: []
//           destinationAddressPrefixes: []
//         }
//       }
//     ]
//   }
// }

// resource nsg1_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
//   name:nsg1name
//   tags: resourceGroup().tags
//   location: location
//   properties:{
//     securityRules:[
//       {
//         name: 'AllowBastionInbound'
//         properties: {
//           protocol: '*'
//           sourcePortRange: '*'
//           sourceAddressPrefix: bastionSubnetAddressSpace
//           destinationAddressPrefix: '*'
//           access: 'Allow'
//           priority: 100
//           direction: 'Inbound'
//           sourcePortRanges: []
//           destinationPortRanges: [
//             '22'
//             '3389'
//           ]
//           sourceAddressPrefixes: []
//           destinationAddressPrefixes: []
//         }
//       }
//     ]
//   }
// }

resource nsg2_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name:nsg2name
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
    ]
  }
}


resource nsgBastion_resource 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name:nsgBastion
  tags: resourceGroup().tags
  location: location
  properties:{
    securityRules:[
      {
        name: 'AllowHttpsInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
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
        name: 'AllowAzureCloudOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
    ]
  }
}

// resource internalLoadbalancer 'Microsoft.Network/loadBalancers@2023-11-01' = {
//   name: lbName
//   sku: {
//     name: 'Standard'
//     tier: 'Regional'
//   }
//   location: location
//   tags: resourceGroup().tags
//   properties: {
//     frontendIPConfigurations: [
//       {
//         name: 'fe-${lbName}'
//         zones: [
//           '1'
//           '2'
//           '3'
//         ]
//         properties: {
//           privateIPAddressVersion: 'IPv4'
//           privateIPAllocationMethod: 'Dynamic'
//           subnet: {
//             id: virtualNetworkName_resource.properties.subnets[2].id
//           }
//         }
//       }
//     ]
//   }
// }



output virtualNetworkId string = virtualNetworkName_resource.id
output virtualNetworkName string = virtualNetworkName_resource.name

