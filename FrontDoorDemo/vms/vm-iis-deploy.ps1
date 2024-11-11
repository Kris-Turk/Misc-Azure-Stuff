#######################################################################################################################################
###                                                 Variables                                                                       ###
#######################################################################################################################################

# General

$loc = "australiaeast"

$tags = @{   
    Owner="kris.turk@hybrit.co.nz"; `
    ApplicationName="KrisCoffee"; `
    BusinessUnit="Production"; `
    Env="Production"; `
    DR="Essential"
}

$networkRgName = "rg-vnet-hyb-demo-aue-01"
$virtualNetworkName = "vnet-hyb-demo-aue-01"
$subnet0_name = "snet-hyb-iis-demo-aue-01"


# Back up Vault
$vaultRgName = "rg-rsv-hyb-hosted-demo-aue-01"
$snapshotRgName = "AzureBackupRG_australiaeast_1"
$vaultName = "rsv-hyb-hosted-demo-aue-01"
$backupPolicyName = "Policy-demo-7Daily-4Weekly-11Monthly-Backup"
$backupTimeZone = "New Zealand Standard Time"

# Vm
$vmRgName = "rg-vm-hyb-iis-aue-01"
$virtualMachineName = "vm-hyb-iis-01"
$osDiskType = "StandardSSD_LRS"
$osDiskDeleteOption = "Detach"
$virtualMachineSize = "Standard_b2ms"
$nicDeleteOption = "Delete"
$adminUsername = "azure_admin"
$sku = "2022-datacenter-azure-edition-hotpatch"
$zones = "2"


$virtualMachineExtensionCustomScriptUri = ""


#######################################################################################################################################
###                            Deployment                                                                                          ###
#######################################################################################################################################

# Check and enable encryption at host if not already registered
$feature = Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"
if ($feature.RegistrationState -ne "Registered") {
    Write-Host "Enabling encryption at host for the subscription..."
    
    # Enable encryption at host for the subscription
    Register-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute"

    # Wait for registration to complete
    while ((Get-AzProviderFeature -FeatureName "EncryptionAtHost" -ProviderNamespace "Microsoft.Compute").RegistrationState -ne "Registered") {
        Write-Host "Waiting for feature registration to complete..."
        Start-Sleep -Seconds 30
    }

    # Register the provider changes
    Register-AzResourceProvider -ProviderNamespace "Microsoft.Compute"
} else {
    Write-Host "Encryption at host is already registered for this subscription"
}

#################################################### Backup Vault ####################################################
# Check for Resource group and deploy if not exists
& $PSScriptRoot\new-rg.ps1 -tags $tags -name $vaultRgName -loc $loc
& $PSScriptRoot\new-rg.ps1 -tags $tags -name $snapshotRgName -loc $loc


New-AzResourceGroupDeployment -ResourceGroupName $vaultRgName -TemplateFile .\RecoveryVaultHosted.bicep `
    -vaultName $vaultName `
    -backupPolicyName $backupPolicyName `
    -backupTimeZone $backupTimeZone


#################################################### VM ##############################################################
# Check for Resource group and deploy if not exists
& $PSScriptRoot\new-rg.ps1 -tags $tags -name $vmRgName -loc $loc

New-AzResourceGroupDeployment -ResourceGroupName $vmRgName -TemplateFile .\vm_Hosted_IIS_NoDomainJoin.bicep `
    -subnetName $subnet0_name  `
    -vnetName $virtualNetworkName `
    -vnetResourceGroup $networkRgName `
    -virtualMachineName $virtualMachineName `
    -osDiskType $osDiskType `
    -osDiskDeleteOption $osDiskDeleteOption `
    -virtualMachineSize $virtualMachineSize `
    -nicDeleteOption $nicDeleteOption `
    -adminUsername $adminUsername `
    -backupVaultName $vaultName `
    -backupVaultRGName $vaultRgName `
    -backupPolicyName $backupPolicyName `
    -virtualMachineExtensionCustomScriptUri $virtualMachineExtensionCustomScriptUri `
    -sku $sku `
    -zones $zones





