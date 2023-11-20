param functionAppName string
param location string = resourceGroup().location
param hostingPlanId string
param storageAccountName string
@secure()
param storageAccountKey string
@secure()
param openAIEndpoint string
@secure()
param openAIKey string
@secure()
param sqlConnectionString string
param keyVaultName string
param tags object = {}
param applicationInsightsConnectionString string

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
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
      APPLICATIONINSIGHTS_CONNECTION_STRING: applicationInsightsConnectionString
      'AzureSQL.ConnectionString': sqlConnectionString
      'AzureOpenAI.Endpoint': openAIEndpoint
      'AzureOpenAI.Key': openAIKey
    }
  }
}

output name string = functionApp.outputs.name
output uri string = functionApp.outputs.uri
