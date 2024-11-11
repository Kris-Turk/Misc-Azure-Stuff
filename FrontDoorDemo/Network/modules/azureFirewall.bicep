param managementPublicIpName string
param fwPublicIpName string
param fwPolicyName string
param fwName string
param vnetName string
param internalIpAddresses array
param vnets array


param location string = resourceGroup().location
param tags object = resourceGroup().tags


var iisToSqlRulesArray = [for vnet in vnets: {
    ruleType: 'NetworkRule'
    name: '${vnet.vnetName}-allowSqlInbound'
    sourceAddresses: [
      vnet.iisSubnetAddressSpace
    ]
    destinationAddresses: [
      vnet.sqlSubnetAddressSpace
    ]
    destinationPorts: [
      '1433'
    ]
    ipProtocols: [
      'TCP'
    ] 
  }
]

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource manangementPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: managementPublicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
  tags: tags
}

resource fwPublicIp 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: fwPublicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: 'Standard'
  }
  tags: tags
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2023-09-01' = {
  name: fwPolicyName
  location: location
  tags: tags
   properties:{
    sku: {
      tier: 'Basic'
    }
   }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-09-01' = {
  name: fwName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: fwPublicIp.name
        properties: {
          publicIPAddress: {
            id: fwPublicIp.id
          }
          subnet: {
              //access subnet id of subname named fwSubnetName
              id: hubVnet.properties.subnets[0].id 
          }
        }
      }
    ]
    sku: {
      tier: 'Basic'
    }
    managementIpConfiguration: {
      name: manangementPublicIp.name
      properties: {
        publicIPAddress: {
           id: manangementPublicIp.id
        }
        subnet: {
          id: hubVnet.properties.subnets[1].id
        }
      }
    }
    firewallPolicy: {
      id: firewallPolicy.id
    }
  }
}

resource ruleCollectionGroupOutbound 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'OutboundWebTrafficRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'rcg-${location}-outbound-web-traffic'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'AllowInternetOutbound'
            ruleType: 'NetworkRule'
            description: 'Allow outbound web traffic on port 80 and 443'
            sourceAddresses: internalIpAddresses
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '80'
              '443'
            ]
            ipProtocols: [
              'TCP'
            ]
          }
          {
            name: 'AllowSMTPOutbound'
            ruleType: 'NetworkRule'
            description: 'Allow outbound web traffic on port 25'
            sourceAddresses: internalIpAddresses
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '25'
            ]
            ipProtocols: [
              'TCP'
            ]
          }
        ]
      }
    ]
  }
}

resource ruleCollectionGroupOutboundAzure 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  parent: firewallPolicy
  name: 'OutboundAzureRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'rcg-${location}-outbound-services'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'AllowAzureServicesOutbound'
            ruleType: 'NetworkRule'
            description: 'Allow vm services e.g. time, kms'
            sourceAddresses: internalIpAddresses
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '123'
              '1688'
            ]
            ipProtocols: [
              'TCP'
              'UDP'
            ]
          }          
        ]
      }
    ]
  }
  dependsOn: [
    ruleCollectionGroupOutbound
  ]
}

resource ruleCollectionGroupEastWestSQL 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
    name: 'rcg-${location}-sql'
    parent: firewallPolicy
    properties: {
      priority: 200
      ruleCollections: [
        {
          ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
          action: {
            type:'Allow'
          }
          priority: 250
          name: 'rc-inbound-sql'
          rules: iisToSqlRulesArray
        }
      ]
    }
    dependsOn: [
      ruleCollectionGroupOutboundAzure
    ]
}
