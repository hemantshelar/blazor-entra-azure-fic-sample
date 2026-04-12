@description('Principal ID of the user-assigned managed identity (CI/CD).')
param principalId string

@description('Built-in role name to assign at resource group scope (default: Contributor).')
param roleDefinitionId string = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

var roleAssignmentName = guid(resourceGroup().id, principalId, roleDefinitionId)

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
