targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string
@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location
param openAIServiceName string = ''
param openAISkuName string = 'S0'
param embeddingDeploymentName string = 'embeddings'
param embeddingDeploymentCapacity int = 30
param embeddingModelName string = 'text-embedding-ada-002'
@description('Id of the user or app to assign application roles')
param principalId string
@secure()
@description('Application user password')
param appUserPassword string
@secure()
@description('SQL Server administrator password')
param sqlAdminPassword string
param dbServiceName string = ''
param keyVaultName string = ''
param dbName string = 'sqldb'
param storageAccountName string = ''
param functionAppName string = ''
param applicationInsightsName string = ''
param hostingPlanName string = ''
param staticWebAppName string = ''
param logAnalyticsName string = ''
param dashboardName string = ''
@description('Flag to Use keyvault to store and use keys')
param useKeyVault bool = true
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

module openAI 'app/openai.bicep' = {
  name: 'openai'
  params: {
    name: !empty(openAIServiceName) ? openAIServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: openAISkuName
    }
    deployments: [
      {
        name: embeddingDeploymentName
        model: {
          format: 'OpenAI'
          name: embeddingModelName
          version: '2'
        }
        capacity: embeddingDeploymentCapacity
      }
    ]
    keyVaultName: keyVault.outputs.name
    useKeyVault: useKeyVault
  }
}

module database 'app/sqlserver.bicep' = {
  name: 'database'
  params: {
    tags: tags
    location: location
    appUserPassword: appUserPassword
    sqlAdminPassword: sqlAdminPassword
    databaseName: dbName
    keyVaultName: keyVault.outputs.name
    name: !empty(dbServiceName) ? dbServiceName : '${abbrs.sqlServers}catalog-${resourceToken}'
    openAIKey: useKeyVault ? kv.getSecret('openAIKey') : ''
    openAIEndpoint: openAI.outputs.endpoint
    openAIServiceName: openAI.outputs.name
    useKeyVault: useKeyVault
    principalId: principalId
  }
}

module keyVault 'app/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
    location: location
    tags: tags
    principalId: principalId
  }
}

module web 'app/staticwebapp.bicep' = {
  name: 'web'
  params: {
    name: !empty(staticWebAppName) ? staticWebAppName : '${abbrs.webStaticSites}${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'web' })
    sqlConnectionString: useKeyVault ? kv.getSecret('AZURE-SQL-CONNECTION-STRING') : '${database.outputs.connectionString}; Password=${appUserPassword}'
    sqlServerId: database.outputs.id
    sqlServerLocation: location
  }
}

module hostingPlan 'core/host/appserviceplan.bicep' = {
  name: 'hostingPlan'
  params: {
    tags: tags
    location: location
    name: !empty(hostingPlanName) ? hostingPlanName : '${abbrs.webServerFarms}${resourceToken}'
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
    kind: 'linux'
  }
}

module logAnalytics 'core/monitor/loganalytics.bicep' ={
  name: 'logAnalytics'
  params: {
    name: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.insightsComponents}${resourceToken}'
    location: location
  }
}

module applicationInsights 'core/monitor/applicationinsights.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    name: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    includeDashboard: false
    dashboardName: dashboardName
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
  }
}

module functionApp 'app/functions.bicep' = {
  name: 'function'
  params: {
    tags: union(tags, { 'azd-service-name': 'functionapp' })
    location: location
    storageAccountName: storageAccount.outputs.name
    openAIKey: useKeyVault ? kv.getSecret('openAIKey') : ''
    functionAppName: !empty(functionAppName) ? functionAppName : '${abbrs.webSitesFunctions}${resourceToken}'
    hostingPlanId: hostingPlan.outputs.id
    storageAccountKey: useKeyVault ? kv.getSecret('storageAccountKey') : ''
    sqlConnectionString: useKeyVault ? kv.getSecret('AZURE-SQL-CONNECTION-STRING') : '${database.outputs.connectionString}; Password=${appUserPassword}'
    openAIEndpoint: openAI.outputs.endpoint
    keyVaultName: keyVault.outputs.name
    applicationInsightsConnectionString: applicationInsights.outputs.connectionString
    useKeyVault: useKeyVault
    openAIName: openAI.outputs.name
  }
}

module storageAccount 'app/storageaccount.bicep' = {
  name: 'storage'
  params: {
    tags: tags
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    keyVaultName: keyVault.outputs.name
    useKeyVault: useKeyVault
  }
}

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = if (useKeyVault) {
  name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
}

output AZURE_SQL_SQLSERVICE_CONNECTION_STRING_KEY string = database.outputs.connectionStringKey
output AZURE_FUNCTIONAPP_NAME string = functionApp.outputs.name
output AZURE_KEY_VAULT_ENDPOINT string = keyVault.outputs.endpoint
output AZURE_KEY_VALUT_NAME string = keyVault.outputs.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.outputs.connectionString
output AZURE_STORAGE_NAME string = storageAccount.outputs.name
output AZURE_STATIC_WEB_URL string = web.outputs.uri
output LOG_ANALYTICS_ID string = logAnalytics.outputs.id
output USE_KEY_VAULT bool = useKeyVault
