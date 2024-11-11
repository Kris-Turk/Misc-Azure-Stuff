targetScope = 'subscription'
param rgname string
param location string
param tags object


resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgname
  location: location
  tags: tags
}

output rgName string = resourceGroup.name
output rgId string = resourceGroup.id
