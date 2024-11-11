//new-AzResourceGroupDeployment -ResourceGroupName 'rg-recoveryvault-dev-uks-01' -TemplateFile .\RecoveryVault.bicep

param vaultName string
param location string = resourceGroup().location
param backupPolicyName string
param backupTimeZone string

resource recoveryVault_resource 'Microsoft.RecoveryServices/vaults@2024-04-01' = {
  location: location
  tags: resourceGroup().tags
  name: vaultName
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {
    securitySettings: {
      softDeleteSettings: {
        softDeleteRetentionPeriodInDays: 14
        softDeleteState: 'Enabled'
        enhancedSecurityState: 'Enabled'
      }
    }
    publicNetworkAccess:'Enabled'
     
  }
}

resource recoveryVaultPolicy_resource 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  name: backupPolicyName
  parent: recoveryVault_resource
  properties: {
    backupManagementType: 'AzureIaasVM'
    policyType: 'V2'
    instantRpRetentionRangeInDays: 2
    timeZone: backupTimeZone
    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes: [
          '2022-03-29T02:00:00Z'
        ]
      }
    }
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionTimes: [
          '2022-03-29T02:00:00Z'
        ]
        retentionDuration: {
          count: 7
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
        ]
        retentionTimes: [
          '2022-03-29T02:00:00Z'
        ]
        retentionDuration: {
          count: 4
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 0
              isLast: true
            }
          ]
        }
        retentionScheduleWeekly: null
        retentionTimes: [
          '2022-03-29T02:00:00Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }      
     }
  }
}

