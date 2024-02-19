$rg = 'rg-name'

$webAppOutboundAddresses = (Get-AzWebApp -ResourceGroupName $rg).OutboundIpAddresses.Split(',')

$mySql = Get-AzMySqlFlexibleServer -ResourceGroupName $rg

foreach($ip in $webAppOutboundAddresses) {

    $ruleName = 'WebAppIp_' + $ip.Replace('.','_')

    New-AzMySqlFlexibleServerFirewallRule -ResourceGroupName $rg -ServerName $mySql.name -Name $ruleName -StartIPAddress $ip -EndIPAddress $ip

}