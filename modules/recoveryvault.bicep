param paramlocation string = resourceGroup().location
param paramVaultName string
param vaultStorageType string
param enableCRR bool
param paramSourceResourceId string
param paramVMName string
param paramResourceGroup string = resourceGroup().name

var varSkuName = 'RS0'
var varSkuTier = 'Standard'
var backupPolicyName = 'DefaultPolicy'
var vmProtectionContainerName = 'iaasvmcontainer;iaasvmcontainerv2;'
var vmProtectedItemName = 'vm;iaasvmcontainerv2'

// RECOVERY VAULT
resource resRecoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
  name: paramVaultName
  tags: {
    Owner: 'Sandy'
    Dept: 'Infrastructure'
  }
  location: paramlocation
  sku: {
    name: varSkuName
    tier: varSkuTier
  }
  properties: {

    }
  }

resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2021-03-01' = {
  parent: resRecoveryServicesVault
  name: backupPolicyName
  location: paramlocation
  properties: {
    backupManagementType: 'AzureIaasVM'
    instantRpRetentionRangeInDays: 5
    schedulePolicy: {
      scheduleRunFrequency: 'Daily'
      scheduleRunTimes: [
        '2023-10-27T10:00:00Z'
      ]
      schedulePolicyType: 'SimpleSchedulePolicy'
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: [
          '2023-10-27T10:00:00Z'
        ]
        retentionDuration: {
          count: 104
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
          'Sunday'
          'Tuesday'
          'Thursday'
        ]
        retentionTimes: [
          '2023-10-27T10:00:00Z'
        ]
        retentionDuration: {
          count: 104
          durationType: 'Weeks'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Daily'
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: [
          '2023-10-27T10:00:00Z'
        ]
        retentionDuration: {
          count: 60
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Daily'
        monthsOfYear: [
          'January'
          'March'
          'August'
        ]
        retentionScheduleDaily: {
          daysOfTheMonth: [
            {
              date: 1
              isLast: false
            }
          ]
        }
        retentionTimes: [
          '2023-10-27T10:00:00Z'
        ]
        retentionDuration: {
          count: 10
          durationType: 'Years'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }
    timeZone: 'UTC'
  }
}

resource resRecoveryServicesVault_vaultstorageconfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2022-02-01' = {
  parent: resRecoveryServicesVault
  name: 'vaultstorageconfig'
  properties: {
    storageModelType: vaultStorageType
    crossRegionRestoreFlag: enableCRR
  }
}

resource resVmBackup 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2016-06-01' = {
  name: '${paramVaultName}/Azure/${vmProtectionContainerName}${paramResourceGroup};${paramVMName}/${vmProtectedItemName};${paramResourceGroup};${paramVMName}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: backupPolicy.id
    sourceResourceId: paramSourceResourceId
  }
  dependsOn: [
    resRecoveryServicesVault_vaultstorageconfig
  ]
}

output outPolicyId string = backupPolicy.id
output outRSV string = resRecoveryServicesVault.id
