targetScope = 'subscription'
param location string = 'australiaeast'
param tags object = {
  Owner: 'kris.turk@hybrit.co.nz'
  Env: 'Hosted'
  ApplicationName: 'network'
  DR: 'Essentials'
  BusinessUnit: 'Operations'
}

// -------- Hub Network params -------- //
param hubVirtualNetworkName string = 'vnet-hyb-hub-aue-01'
param hubAddressSpaces array = [
  '10.221.0.0/24'
]
param hubsubnet0_name string = 'AzureFirewallSubnet'
param hubsubnet0_addressRange string = '10.221.0.0/26'
param hubsubnet1_name string = 'AzureFirewallManagementSubnet'
param hubsubnet1_addressRange string = '10.221.0.64/26'
param hubsubnet2_name string = 'snet-hyb-lb-aue-01'
param hubsubnet2_addressRange string = '10.221.0.128/27'
param bastionName string = 'bastion-hyb-aue-01'
param bastionSubnetName string = 'AzureBastionSubnet'
param bastionSubnetAddressSpace string = '10.221.0.224/27'
param hubsubid string = subscription().subscriptionId

// Add all IP address space IP's for any new vnets
param internalIpAddresses array = [
  '10.221.0.0/24'
  '10.221.1.0/24'
]


// -------- Spoke Network params -------- //
param spoke1RgName string = 'rg-vnet-hyb-demo-aue-01'
param spokevirtualNetworkName string = 'vnet-hyb-demo-aue-01'
param spokeaddressSpaces array = [
  '10.221.1.0/24'
]

param spokesubnets array = [
  {
    name: 'snet-hyb-iis-demo-aue-01'
    subnetPrefix: '10.221.1.0/27'
    rt: 'true'
    nsg: 'true'
    function: 'iis'
  }
  {
    name: 'snet-hyb-db-demo-aue-01'
    subnetPrefix: '10.221.1.32/27'
    rt: 'true'
    nsg: 'true'
    function: 'db'
  }
  {
    name: 'snet-hyb-lb-demo-aue-01'
    subnetPrefix: '10.221.1.224/27'
    rt: 'true'
    nsg: 'true'
    function: 'lb'
  }
  {
    name: 'snet-hyb-smtp-demo-aue-01'
    subnetPrefix: '10.221.1.64/27'
    rt: 'true'
    nsg: 'true'
    function: 'smtp'
  }
]



param spoke1subid string = subscription().subscriptionId

param firewallPrivateIP string = '10.221.0.4'


// Used to dynamically create firewall Rules
var vnets = [
  {
    vnetName: spokevirtualNetworkName

    iisSubnetAddressSpace: spokesubnets[0].subnetPrefix
    sqlSubnetAddressSpace: spokesubnets[1].subnetPrefix
  }  
]

// -------- Azure Firewall params -------- //

param managementPublicIpName string = 'pip-mgmt-fw-hyb-aue-01'
param fwPublicIpName string = 'pip-fw-hyb-aue-01'
param fwPolicyName string = 'policy-fw-hyb-aue-01'
param fwName string = 'fw-hyb-aue-01'



// -------- Load Balancer params -------- //

// param lbName string = 'lb-hyb-aue-01'


// -------- Deployment -------- //

resource rgVnetHub 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-vnet-hyb-hub-aue-01'
  location: location
  tags: tags
}

resource rgNetworkWatcherHub 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'NetworkWatcherRG'
  location: location
  tags: tags
}

module rgVnetSpoke1_m 'modules/resourcegroup.bicep' = {
  scope: subscription(spoke1subid)
  name: spoke1RgName
  params: {
    location: location
    rgname: spoke1RgName
    tags: tags
  }
}

module rgVnetSpoke1NetworkWatcher_m 'modules/resourcegroup.bicep' = {
  scope: subscription(spoke1subid)
  name: 'NetworkWatcher${location}'
  params: {
    location: location
    rgname: 'NetworkWatcherRG'
    tags: tags
  }
}


// deploy virtual network vnet-hub-aue-01 using module hubnetwork.bicep
module vnetHubModule './modules/hubnetwork.bicep' = {
  name: 'vnet-hyb-hub-aue-01'
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
}

// deploy virtual network for JAL using module 
module vnetSpoke1Module './modules/networkspoke.bicep' = {
  name: spokevirtualNetworkName
  scope: resourceGroup(spoke1subid,spoke1RgName)
  params: {
    location: location
    virtualNetworkName: spokevirtualNetworkName
    addressSpaces: spokeaddressSpaces
    subnets: spokesubnets
    bastionSubnetAddressSpace: bastionSubnetAddressSpace
    // dnsServers: dnsServers
    peeredvNet_name: hubVirtualNetworkName
    peeredvNet_rg: rgVnetHub.name
    peeredvnet_sub: hubsubid
    subid: spoke1subid
    firewallPrivateIP: firewallPrivateIP
  }
  dependsOn: [
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
    vnetName: vnetHubModule.outputs.virtualNetworkName
    internalIpAddresses: internalIpAddresses
    tags: tags
    vnets: vnets
  }
}


