param functionAppName string
param location string = resourceGroup().location
param hostingPlanId string
param storageAccountName string
param applicationInsightsConnectionString string
@secure()
param storageAccountKey string
@secure()
param openAIEndpoint string
@secure()
param openAIKey string
@secure()
param sqlConnectionString string
param tags object = {}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: hostingPlanId
    siteConfig: {
      netFrameworkVersion: 'v7.0'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccountKey}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'AzureSQL.ConnectionString'
          value: sqlConnectionString
        }
        {
          name: 'AzureOpenAI.Endpoint'
          value: openAIEndpoint
        }
        {
          name: 'AzureOpenAI.Key'
          value: openAIKey
        }
      ]

      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

output name string = functionApp.name
