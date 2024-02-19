param targetScopes array = [
  '/providers/Microsoft.Management/managementGroups/${tenant().tenantId}' // Tenant root Group, the tenant() funtion can be replaced with a specific mangementgroup name
  // subscription().id  // deploys to subscription of current Context, can be replaced by spefic subscriptions or removed
]

@description('Array of actions for the roleDefinition')
param actions array = [
  'Microsoft.Web/sites/Read'
  'microsoft.web/sites/*/read'
]

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string = 'App Reader'

@description('Detailed description of the role definition')
param roleDescription string = 'Reader privilege for Web App and Function app, including confiugration'

param roleDefName string = guid(subscription().id, string(actions), string(notActions))


resource roleDef_r 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: targetScopes
  }
}
