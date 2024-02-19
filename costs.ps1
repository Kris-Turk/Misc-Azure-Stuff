# https://github.com/mivano/azure-cost-cli

# Requires both Azure CLI and Azure PowerShell login to same Tennt

$datefrom = '2023-10-01'
$dateTo = '2023-10-31'

$subs = Get-AzSubscription

$grandTotal = 0

foreach ($sub in $subs) {
    #Write-Host "Subscription: $($sub.Name)"
    $data = azure-cost accumulatedCost -t custom --from $dateFrom --to $dateTo -o csv -s $sub.id
    $data = $data[6..($data.length -1)]
    $monthTotal = 0
    foreach ($line in $data) {
        $monthTotal += [decimal]$line.split(',')[1]
    }
    #write-host "Cumlative Total for $($sub.name) on $($dateTo): $monthtotal"
    write-host $monthTotal
    $grandTotal += $monthTotal
}

Write-Host "Grand Total of all subs on $($dateTo): $grandTotal"


