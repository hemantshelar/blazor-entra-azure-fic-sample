targetScope = 'subscription'

@description('Name of the resource group for this environment.')
param resourceGroupName string

@description('Azure region for all resources.')
param location string

@description('Short environment label (e.g. dev, prod).')
param environmentName string

@description('Prefix for resource names (must yield globally unique web app name).')
param appNamePrefix string

@description('GitHub org or user (for federated credential subject).')
param githubOrg string

@description('GitHub repository name.')
param githubRepo string

@description('Git ref for FIC subject (e.g. refs/heads/main).')
param githubRef string = 'refs/heads/main'

@description('App Service Plan SKU (e.g. B1).')
param appServiceSku string = 'B1'

@description('Linux runtime stack for the Web App.')
param linuxFxVersion string = 'DOTNETCORE|10.0'

@description('Optional Entra tenant ID for app settings (or leave empty).')
param azureAdTenantId string = ''

@description('Optional Entra app (client) ID.')
param azureAdClientId string = ''

@description('Optional Entra domain (e.g. contoso.onmicrosoft.com).')
param azureAdDomain string = ''

var cicdIdentityName = '${appNamePrefix}-uami-cicd-${environmentName}'
var federatedCredentialName = 'github-${replace(replace(replace(githubRef, '/', '-'), ':', '-'), '_', '-')}'
var githubSubject = 'repo:${githubOrg}/${githubRepo}:ref:${githubRef}'
var resourceNameSuffix = uniqueString(subscription().subscriptionId, resourceGroupName, environmentName)

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    logAnalyticsName: 'law-${environmentName}-${resourceNameSuffix}'
    appInsightsName: 'ai-${environmentName}-${resourceNameSuffix}'
  }
}

module appService 'modules/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    location: location
    appServicePlanName: '${appNamePrefix}-plan-${environmentName}'
    webAppName: '${appNamePrefix}-web-${environmentName}'
    skuName: appServiceSku
    linuxFxVersion: linuxFxVersion
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    azureAdTenantId: azureAdTenantId
    azureAdClientId: azureAdClientId
    azureAdDomain: azureAdDomain
  }
}

module cicdIdentity 'modules/managed-identity-cicd.bicep' = {
  name: 'cicd-identity'
  scope: rg
  params: {
    location: location
    cicdManagedIdentityName: cicdIdentityName
    federatedCredentialName: take(federatedCredentialName, 120)
    githubActionsSubject: githubSubject
  }
}

module cicdRbac 'modules/rbac.bicep' = {
  name: 'cicd-rbac'
  scope: rg
  params: {
    principalId: cicdIdentity.outputs.cicdIdentityPrincipalId
  }
}

output resourceGroupName string = rg.name
output webAppName string = appService.outputs.webAppName
output webAppHostName string = appService.outputs.webAppDefaultHostName
output webAppResourceId string = appService.outputs.webAppResourceId
output cicdIdentityClientId string = cicdIdentity.outputs.cicdIdentityClientId
output cicdIdentityPrincipalId string = cicdIdentity.outputs.cicdIdentityPrincipalId
output githubFederatedSubject string = githubSubject
