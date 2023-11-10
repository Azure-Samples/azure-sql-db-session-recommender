targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string
@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location
param openAiServiceName string = ''
param openAiSkuName string = 'S0'
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
param appUser string = 'appUser'
param sqlAdmin string = 'sqlAdmin'
param dbServiceName string =''
param keyVaultName string =''
param dbName string ='sqldb'
@secure()
param repositoryToken string
@secure()
param repositoryUrl string
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var appName = 'session-recommender'
var appId = uniqueString(resourceGroup().id)
var staticWebAppName = '${appName}-${appId}'
var functionAppName = '${appName}-api-${appId}'
var hostingPlanName = '${appName}-plan-${appId}'
var applicationInsightsName = '${appName}-ai-${appId}'
var storageAccountName = '${appId}storage'

module openAi 'app/openai.bicep' =  {
  name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
  params: {
    name: !empty(openAiServiceName) ? openAiServiceName : '${abbrs.cognitiveServicesAccounts}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: openAiSkuName
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
  }
}
// USER ROLES
module openAiRoleUser 'core/security/role.bicep' = {
  name: 'openai-role-user'
  params: {
    principalId: principalId
    roleDefinitionId: '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'
    principalType: 'User'
  }
}
module dataBase 'app/sqlserver.bicep' ={
  name: !empty(dbServiceName) ? dbServiceName : '${abbrs.sqlServers}catalog-${resourceToken}'
  params:{
    location: location
    appUserPassword: appUserPassword
    sqlAdminPassword: sqlAdminPassword
    databaseName: dbName
    keyVaultName: keyVault.outputs.name
    name: !empty(dbServiceName) ? dbServiceName : '${abbrs.sqlServers}catalog-${resourceToken}'
    openAIUrl: openAi.outputs.endpoint
    appUser: appUser
    sqlAdmin: sqlAdmin
    openAIKey: kv.getSecret('openAlKey')
  }
}
// Store secrets in a keyvault
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
  params:{
    name: staticWebAppName
    location: location
    tags: union(tags, { 'azd-service-name': 'web'})
    repositoryToken: repositoryToken
    repositoryUrl: repositoryUrl
    sqlConnectionString: kv.getSecret('AZURE-SQL-CONNECTION-STRING')
    sqlServerId: dataBase.outputs.id
    sqlServerLocation: dataBase.outputs.location
  }
}
module hostingPlan 'core/host/appserviceplan.bicep'= {
  name: 'hostingPlan'
  params: {
    location: location
    name: hostingPlanName
    sku: {
      name: 'Y1'
      tier: 'Dynamic'
    }
    reserved: false
  }
}
module applicationInsights 'app/applicationInsights.bicep' = {
  name: 'applicationInsights'
  params: {
    name: applicationInsightsName
    location: location
    keyVaultName: keyVault.outputs.name
  }
}
module functionApp 'app/functions.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    storageAccountName: storageAccount.name
    instrumentationKey: kv.getSecret('instrumentationKey')
    openAIEndpoint: openAi.outputs.endpoint
    openAiKey: kv.getSecret('openAlKey')
    functionAppName: functionAppName
    hostingPlanId: hostingPlan.outputs.id
    storageAccountKey: kv.getSecret('storageAccountKey')
    sqlConnectionString: kv.getSecret('AZURE-SQL-CONNECTION-STRING')
  }
  dependsOn: [dataBase]
}
module storageAccount 'app/storageaccount.bicep' = {
  name: storageAccountName
  params: {
    name: storageAccountName
    location: location
    keyVaultName: keyVault.outputs.name
  }
}
resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: !empty(keyVaultName) ? keyVaultName : '${abbrs.keyVaultVaults}${resourceToken}'
}

output FUNCTIONAPP_NMAE string = functionApp.outputs.name

