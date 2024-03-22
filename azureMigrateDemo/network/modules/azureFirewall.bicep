param managementPublicIpName string
param fwPublicIpName string
param fwPolicyName string
param fwName string
param vnetName string
param onpremip string



param location string = resourceGroup().location
param tags object = resourceGroup().tags

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
  name: 'DefaultNetworkRuleCollectionGroup'
  properties: {
    priority: 200
    ruleCollections: [
      {
        name: 'OutboundInternet'
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        priority: 1000
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'AllowInternetOutbound'
            
            destinationAddresses: [
              '*'
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
            sourceAddresses: [
              '*'
            ]          

          }
        ]
      }
    ]
  }
}

resource ruleCollectionGroupinbound 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2023-09-01' = {
  name: 'DefaultDnatRuleCollectionGroup'
  parent: firewallPolicy
  properties: {
    priority: 100
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyNatRuleCollection'
        action: {
          type: 'Dnat'
        }
        name: 'AzureMigrate'
        priority: 2000
        rules: [
          {
            ruleType: 'NatRule'
            destinationAddresses: [
              fwPublicIp.properties.ipAddress
            ]
            destinationPorts: [
              '443'
              '9443'
            ]
            ipProtocols: [
              'TCP'
            ]
            name: 'AzureMigrate'
            sourceAddresses: [
              onpremip
            ]
            translatedAddress: '10.210.1.4'
            translatedPort: '9443'
          }
          {
            ruleType: 'NatRule'
            destinationAddresses: [
              fwPublicIp.properties.ipAddress
            ]
            destinationPorts: [
              '445'
            ]
            ipProtocols: [
              'TCP'
            ]
            name: 'SMB'
            sourceAddresses: [
              onpremip
            ]
            translatedAddress: '10.210.1.4'
            translatedPort: '445'
          }
        ]
      }
    ]
  }
}
