$badSubnets = ((Get-AzVirtualNetwork | Get-AzVirtualNetworkSubnetConfig) | Where-Object { $_.networksecuritygroup -eq $null }).name


foreach($bs in $badSubnets){
    $nsgName = 'nsg-' + $bs.name
    $rg = $bs.Id.Split('/')[4]
    $vNetName = $bs.Id.Split('/')[8]
    $vNet = Get-AzVirtualNetwork -ResourceGroupName $rg -Name $vNetName
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $rg -Name $nsgName -Location $vNet.Location -Force
    Set-AzVirtualNetworkSubnetConfig -Name $bs.Name -VirtualNetwork $vNet -AddressPrefix $bs.AddressPrefix -NetworkSecurityGroupId $nsg.Id
    $vNet | Set-AzVirtualNetwork

}