param location string
param tags object
param nsg0Name string
param nsg1Name string
param nsg2Name string
param nsg3Name string

param storageAccountRgName string
param storageAccountName string
param networkRgName string
param flowLogRetentionDays int
param flowLogVersion int


resource networkWatcher_r 'Microsoft.Network/networkWatchers@2023-11-01' existing = {
  name: 'NetworkWatcher_${location}'
}

resource storageAccount_r 'Microsoft.Storage/storageAccounts@2023-04-01' existing = {
  scope: resourceGroup(storageAccountRgName)
  name: storageAccountName
}

resource nsg0_r 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  scope: resourceGroup(networkRgName)
  name: nsg0Name
}

resource nsg0flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  name: 'flow-${nsg0Name}'
  parent: networkWatcher_r
  tags: tags
  location: location
  properties:{
    storageId: storageAccount_r.id
    targetResourceId: nsg0_r.id
    enabled: true
    format: {
      type: 'JSON'
      version: flowLogVersion
    }
    flowAnalyticsConfiguration: {}
    retentionPolicy: {
      days: flowLogRetentionDays
      enabled: true
    }
  }
}


resource nsg1_r 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  scope: resourceGroup(networkRgName)
  name: nsg1Name
}

resource nsg1flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  name: 'flow-${nsg1Name}'
  parent: networkWatcher_r
  tags: tags
  location: location
  properties:{
    storageId: storageAccount_r.id
    targetResourceId: nsg1_r.id
    enabled: true
    format: {
      type: 'JSON'
      version: flowLogVersion
    }
    flowAnalyticsConfiguration: {}
    retentionPolicy: {
      days: flowLogRetentionDays
      enabled: true
    }
  }
}

resource nsg2_r 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  scope: resourceGroup(networkRgName)
  name: nsg2Name
}

resource nsg2flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  name: 'flow-${nsg2Name}'
  parent: networkWatcher_r
  tags: tags
  location: location
  properties:{
    storageId: storageAccount_r.id
    targetResourceId: nsg2_r.id
    enabled: true
    format: {
      type: 'JSON'
      version: flowLogVersion
    }
    flowAnalyticsConfiguration: {}
    retentionPolicy: {
      days: flowLogRetentionDays
      enabled: true
    }
  }
}

resource nsg3_r 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  scope: resourceGroup(networkRgName)
  name: nsg3Name
}

resource nsg3flowLog 'Microsoft.Network/networkWatchers/flowLogs@2023-11-01' = {
  name: 'flow-${nsg3Name}'
  parent: networkWatcher_r
  tags: tags
  location: location
  properties:{
    storageId: storageAccount_r.id
    targetResourceId: nsg3_r.id
    enabled: true
    format: {
      type: 'JSON'
      version: flowLogVersion
    }
    flowAnalyticsConfiguration: {}
    retentionPolicy: {
      days: flowLogRetentionDays
      enabled: true
    }
  }
}
