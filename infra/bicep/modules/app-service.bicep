@description('Azure region.')
param location string

@description('App Service plan name.')
param appServicePlanName string

@description('Web App name (globally unique across Azure).')
param webAppName string

@description('App Service Plan SKU name (e.g. B1, P1v3).')
param skuName string = 'B1'

@description('Linux stack: DOTNETCORE|10.0, DOTNETCORE|9.0, etc.')
param linuxFxVersion string = 'DOTNETCORE|10.0'

@description('Application Insights connection string for the web app.')
param appInsightsConnectionString string

@description('Optional Entra settings (set via pipeline secrets or leave empty and configure manually).')
param azureAdInstance string = environment().authentication.loginEndpoint
param azureAdTenantId string = ''
param azureAdClientId string = ''
param azureAdDomain string = ''

var alwaysOn = skuName != 'F1' && skuName != 'D1'

var baseAppSettings = {
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsightsConnectionString
  ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
}

var adAppSettings = empty(azureAdTenantId) ? {} : {
  AzureAd__Instance: azureAdInstance
  AzureAd__TenantId: azureAdTenantId
  AzureAd__ClientId: azureAdClientId
  AzureAd__Domain: azureAdDomain
  AzureAd__CallbackPath: '/signin-oidc'
  AzureAd__SignedOutCallbackPath: '/signout-callback-oidc'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: alwaysOn
      http20Enabled: true
      minTlsVersion: '1.2'
    }
  }
}

resource webAppSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: webApp
  name: 'appsettings'
  properties: union(baseAppSettings, adAppSettings)
}

output webAppName string = webApp.name
output webAppDefaultHostName string = webApp.properties.defaultHostName
output webAppPrincipalId string = webApp.identity.principalId
output webAppResourceId string = webApp.id
