$keys = @("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run", "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32","HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder")

$appsToDisable = @("Greenshot","Redirector")

# Binary Value for Disabled
$binaryValue = [byte[]](3, 0, 0, 0, 135, 159, 80, 94, 164, 19, 219, 1)


foreach($app in $appsToDisable){
    foreach($key in $keys){
        $appKey = Get-ItemProperty -Path $key -Name $app -ErrorAction SilentlyContinue
        if($appKey -ne $null){
            Write-Host "Disabling $app"
            Set-ItemProperty -Path $key -Name $app -Value $binaryValue
        }
    }
}
