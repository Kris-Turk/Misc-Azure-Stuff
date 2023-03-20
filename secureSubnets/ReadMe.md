![kristurk.com](../img/kristurk_logo.png)

# Securing All Subnets

[TOC]

## Introduction

Securing Azure subnets with network security groups (NSGs) is important to protect the resources and data within the subnets from unauthorized access, both from within the network and from external sources.

Network security groups act as a virtual firewall for the Azure virtual network, controlling inbound and outbound traffic to and from resources in the subnet. They allow you to create rules that define which traffic is allowed and which traffic is blocked, based on the source and destination IP addresses, protocols, and ports.

By applying NSGs to subnets, you can enforce network security policies that restrict access to critical resources and data, and prevent attacks such as Distributed Denial of Service (DDoS) attacks, malware, and other threats.

NSGs can also be used in conjunction with other Azure security features, such as Azure Firewall and Azure Virtual Private Network (VPN), to provide multi-layered security for your Azure resources and network.

Overall, securing Azure subnets with network security groups is a crucial step in protecting your organization's data and resources, and ensuring the security and integrity of your Azure infrastructure.

## Usage/Instructions

Use the [nsg.ps1](./nsg.ps1) file to search all subnets within a given subscription for missing NSG's. If you run the script as is it will create and attach an NSG with default rules to any subnets that are not currently protected. This is the minimum recommended protection for most situations.

The naming convention used will be to use the name of the subnet prefixed with <u>nsg-</u>

You can also simply copy the script from the block below

```powershell
$badSubnets = (Get-AzVirtualNetwork | Get-AzVirtualNetworkSubnetConfig) | Where-Object { $_.networksecuritygroup -eq $null }


foreach($bs in $badSubnets){
    $nsgName = 'nsg-' + $bs.name
    $rg = $bs.Id.Split('/')[4]
    $vNetName = $bs.Id.Split('/')[8]
    $vNet = Get-AzVirtualNetwork -ResourceGroupName $rg -Name $vNetName
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName -Location $vNet.Location -Force
    Set-AzVirtualNetworkSubnetConfig -Name $bs.Name -VirtualNetwork $vNet -AddressPrefix $bs.AddressPrefix -NetworkSecurityGroupId $nsg.Id
    $vNet | Set-AzVirtualNetwork

}
```



