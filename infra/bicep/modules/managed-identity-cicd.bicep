@description('Azure region.')
param location string

@description('User-assigned managed identity name for GitHub Actions (OIDC).')
param cicdManagedIdentityName string

@description('Federated credential name (e.g. github-main).')
param federatedCredentialName string

@description('GitHub Actions token subject (must match workflow ref/environment). Example: repo:org/repo:ref:refs/heads/main')
param githubActionsSubject string

resource cicdIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: cicdManagedIdentityName
  location: location
}

resource githubFic 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: cicdIdentity
  name: federatedCredentialName
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: githubActionsSubject
    audiences: [
      'api://AzureADTokenExchange'
    ]
  }
}

output cicdIdentityId string = cicdIdentity.id
output cicdIdentityPrincipalId string = cicdIdentity.properties.principalId
output cicdIdentityClientId string = cicdIdentity.properties.clientId
