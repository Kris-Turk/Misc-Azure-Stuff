param ($tags,$loc,$name)

if (!(Get-AzResourceGroup -ResourceGroupName $name -ErrorAction SilentlyContinue)) { 
    New-AzResourceGroup -Name $name -Location $loc -Tag $tags -Force 
} else {
    write-host("Resource group already exists")
}