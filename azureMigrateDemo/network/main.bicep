targetScope = 'subscription'
param location string = 'australiaeast'
param tags object = {
  owner: 'kris.turk@hybrit.co.nz'
  environment: 'demo'
  application: 'network'
}

// -------- Hub Network params -------- //
param hubVirtualNetworkName string = 'vnet-hyb-demo-hub-aue-01'
param hubAddressSpaces array = [
  '10.210.0.0/24'
]
param hubsubnet0_name string = 'AzureFirewallSubnet'
param hubsubnet0_addressRange string = '10.210.0.0/26'
param hubsubnet1_name string = 'AzureFirewallManagementSubnet'
param hubsubnet1_addressRange string = '10.210.0.64/26'
param hubsubnet2_name string = 'snet-hyb-demo-gateway-hub-aue-01'
param hubsubnet2_addressRange string = '10.210.0.128/27'
param bastionName string = 'bastion-hyb-demo-hub-aue-01'
param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetAddressSpace string = '10.210.0.224/27'
param hubsubid string = subscription().subscriptionId


// -------- Migration Spoke Network params -------- //
param spokevirtualNetworkName string = 'vnet-hyb-demo-migrate-aue-01'
param spokeaddressSpaces array = [
  '10.210.1.0/24'
]

param spokesubnets array = [
  {
    name: 'snet-hyb-demo-migrate-aue-01'
    subnetPrefix: '10.210.1.0/27'
    rt: 'true'
    nsg: 'true'
  }
]

param dnsServers array = [
  '1.1.1.1'
]
param corpAddressRanges array = [
  '10.210.0.0/16'
  '121.79.240.60'
]

param spokesubid string = subscription().subscriptionId

param firewallPrivateIP string = '10.210.0.4'


// -------- Landing Zone Spoke Network params -------- //
param spoke2virtualNetworkName string = 'vnet-hyb-demo-lz-aue-01'
param spoke2addressSpaces array = [
  '10.210.2.0/24'
]

param spoke2subnets array = [
  {
    name: 'snet-hyb-demo-migrate-aue-01'
    subnetPrefix: '10.210.2.0/27'
    rt: 'true'
    nsg: 'true'
  }
]




param spoke2subid string = subscription().subscriptionId



// -------- Azure Firewall params -------- //

param managementPublicIpName string = 'pip-mgmt-fw-hyb-demo-aue-01'
param fwPublicIpName string = 'pip-fw-hyb-demo-aue-01'
param fwPolicyName string = 'policy-fw-hyb-demo-aue-01'
param fwName string = 'fw-hyb-demo-aue-01'
param onpremip string = '121.79.240.60'

// -------- Deployment -------- //

resource rgVnetHub 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-vnet-hyb-demo-hub-aue-01'
  location: location
  tags: tags
}

resource rgVnetSpoke1 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-vnet-hyb-demo-migrate-aue-01'
  location: location
  tags: tags
}

resource rgVnetSpoke2 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-vnet-hyb-demo-lz-aue-01'
  location: location
  tags: tags
}


// deploy virtual network vnet-hub-aue-01 using module hubnetwork.bicep
module vnetHubModule './modules/hubnetwork.bicep' = {
  name: 'vnet-hyb-demo-hub-aue-01'
  scope: resourceGroup(rgVnetHub.name)
  params: {
    location: location
    virtualNetworkName: hubVirtualNetworkName
    addressSpaces: hubAddressSpaces
    subnet0_name: hubsubnet0_name
    subnet0_addressRange: hubsubnet0_addressRange
    subnet1_name: hubsubnet1_name
    subnet1_addressRange: hubsubnet1_addressRange
    subnet2_name: hubsubnet2_name
    subnet2_addressRange: hubsubnet2_addressRange
    bastionName: bastionName
    bastionSubnetName: bastionSubnetName
    bastionSubnetAddressSpace: bastionSubnetAddressSpace   

  }
  dependsOn: [
    rgVnetHub
  ]
}

// deploy virtual network vnet-migrate-aue-01 using module 
module vnetSpoke1Module './modules/networkspoke.bicep' = {
  name: spokevirtualNetworkName
  scope: resourceGroup(rgVnetSpoke1.name)
  params: {
    location: location
    virtualNetworkName: spokevirtualNetworkName
    addressSpaces: spokeaddressSpaces
    subnets: spokesubnets
    bastionSubnetAddressSpace: bastionSubnetAddressSpace
    corpAddressRanges: corpAddressRanges
    dnsServers: dnsServers
    peeredvNet_name: hubVirtualNetworkName
    peeredvNet_rg: rgVnetHub.name
    peeredvnet_sub: hubsubid
    subid: spokesubid
    firewallPrivateIP: firewallPrivateIP
  }
  dependsOn: [
    rgVnetSpoke1
    vnetHubModule
  ]
}

// deploy virtual network vnet-migrate-aue-02 using module 
module vnetSpoke2Module './modules/networkspoke.bicep' = {
  name: spoke2virtualNetworkName
  scope: resourceGroup(rgVnetSpoke2.name)
  params: {
    location: location
    virtualNetworkName: spoke2virtualNetworkName
    addressSpaces: spoke2addressSpaces
    subnets: spoke2subnets
    bastionSubnetAddressSpace: bastionSubnetAddressSpace
    corpAddressRanges: corpAddressRanges
    dnsServers: dnsServers
    peeredvNet_name: hubVirtualNetworkName
    peeredvNet_rg: rgVnetHub.name
    peeredvnet_sub: hubsubid
    subid: spoke2subid
    firewallPrivateIP: firewallPrivateIP
  }
  dependsOn: [
    rgVnetSpoke1
    vnetHubModule
  ]
}

module azureFirewall './modules/azurefirewall.bicep' = {
  name: fwName
  scope: resourceGroup(rgVnetHub.name)
  params: {
    location: location
    fwName: fwName
    fwPublicIpName: fwPublicIpName
    fwPolicyName: fwPolicyName
    managementPublicIpName: managementPublicIpName
    vnetName: hubVirtualNetworkName
    onpremip: onpremip
  }
  dependsOn: [
    vnetHubModule
  ]
}

