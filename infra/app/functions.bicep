param functionAppName string
param location string = resourceGroup().location
param hostingPlanId string
param storageAccountName string
@secure()
param openAIEndpoint string
@secure()
param sqlConnectionString string
param keyVaultName string
param tags object = {}
param applicationInsightsConnectionString string
param openAIName string
param openAIDeploymentName string = 'embeddings'

module functionApp '../core/host/functions.bicep' = {
  name: 'function1'
  params: {
    location: location
    alwaysOn: false
    tags: union(tags, { 'azd-service-name': 'functionapp' })
    kind: 'functionapp'
    keyVaultName: keyVaultName
    appServicePlanId: hostingPlanId
    name: functionAppName
    runtimeName: 'dotnet'
    runtimeVersion: 'v7.0'
    storageAccountName: storageAccountName
    appSettings: {
      WEBSITE_CONTENTSHARE: toLower(functionAppName)
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.Storage/storageAccounts', storageAccountName), '2022-05-01').keys[0].value}'
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
      'AzureSQL.ConnectionString': sqlConnectionString
      'AzureOpenAI.Endpoint': openAIEndpoint
      'AzureOpenAI.DeploymentName': openAIDeploymentName
      'AzureOpenAI.Key': listKeys(resourceId(subscription().subscriptionId, resourceGroup().name, 'Microsoft.CognitiveServices/accounts', openAIName), '2023-05-01').key1
    }
  }
}

output name string = functionApp.outputs.name
output uri string = functionApp.outputs.uri
