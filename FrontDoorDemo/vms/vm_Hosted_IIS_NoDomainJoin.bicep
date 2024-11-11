// Parameters
param location string = resourceGroup().location

param subnetName string
param vnetName string
param vnetResourceGroup string
param virtualMachineName string
param osDiskType string
param osDiskDeleteOption string
param virtualMachineSize string
param nicDeleteOption string
param adminUsername string
@secure()
param adminPassword string
param sku string = '2022-Datacenter'

param backupVaultName string
param backupFabricName string = 'Azure'
param backupVaultRGName string
param backupPolicyName string
param zones string

// The URI of the PowerShell Custom Script.
// param virtualMachineExtensionCustomScriptUri string

// Variable Declarations
var backupItemName  = 'vm;iaasvmcontainerv2;${resourceGroup().name};${virtualMachineName}'
var networkInterfaceName  = 'nic-${virtualMachineName}'
var dataDiskName1 = '${virtualMachineName}_Data_Disk_01'


resource virtualNetwork_resource 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: vnetName
  scope: resourceGroup(vnetResourceGroup)
}

resource networkInterface_resource 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${virtualNetwork_resource.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource virtualMachine_r 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: virtualMachineName
  identity: {
    type: 'SystemAssigned'
  }
  location: location

  zones: [
    zones
  ]

  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: sku
        version: 'latest'
      }

      dataDisks: [
        {
          lun: 0
          name: dataDiskName1
          createOption: 'Empty'
          caching: 'ReadOnly'
          writeAcceleratorEnabled: false
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
          deleteOption: 'Detach'
          diskSizeGB: 64
          toBeDetached: false
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface_resource.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }

    securityProfile: {
      encryptionAtHost: true
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }

    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          automaticByPlatformSettings: {
            rebootSetting: 'Never'
          }
          enableHotpatching: true
          patchMode: 'AutomaticByPlatform'
          assessmentMode: 'AutomaticByPlatform'          
        }
      }
    }

    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    licenseType: 'Windows_Server' //AHUB license
  }
}

module virtualMachineName_BackupIntent './modules/vmBackupModule.bicep' = {
  name: '${virtualMachine_r.name}-BackupIntent'
  scope: resourceGroup(backupVaultRGName)
  params: {
    backupPolicy_resourceId: resourceId(backupVaultRGName, 'Microsoft.RecoveryServices/vaults/backupPolicies', backupVaultName, backupPolicyName)
    vm_resourceId: virtualMachine_r.id
    backupVaultName: backupVaultName
    backupFabricName: backupFabricName
    backupItemName: backupItemName
    virtualMachineName: virtualMachineName
  }
}

// resource DefaultApps_r 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
//   parent: virtualMachine_r
//   name: 'DefaultApps'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Compute'
//     type: 'CustomScriptExtension'
//     typeHandlerVersion: '1.10'
//     autoUpgradeMinorVersion: true
//     settings: {
//       fileUris: [
//         virtualMachineExtensionCustomScriptUri
//       ]
//       commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ./${last(split(virtualMachineExtensionCustomScriptUri, '/'))}'
//     }
//     protectedSettings: {}
//   }
// }

resource entraIdLogin_r 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  name: 'AADLoginForWindows'
  parent: virtualMachine_r
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmId: ''
    }
  }
}

