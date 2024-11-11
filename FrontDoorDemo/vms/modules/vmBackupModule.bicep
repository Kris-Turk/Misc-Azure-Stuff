param backupPolicy_resourceId string
param vm_resourceId string
param backupVaultName string
param backupFabricName string
param backupItemName string
param virtualMachineName string

resource backupItem_resource 'Microsoft.RecoveryServices/vaults/backupFabrics/backupProtectionIntent@2022-01-01' = {
  name: '${backupVaultName}/${backupFabricName}/${backupItemName}'
  properties: {
    friendlyName: '${virtualMachineName}BackupIntent'
    protectionIntentItemType: 'AzureResourceItem'
    policyId: backupPolicy_resourceId
    sourceResourceId: vm_resourceId
  }
}
