param functionAppName string
param location string = resourceGroup().location
param hostingPlanId string
param storageAccountName string
@secure()
param instrumentationKey string
@secure()
param openAIEndpoint string
@secure()
param storageAccountKey string
@secure()
param openAiKey string
@secure()
param sqlConnectionString string

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlanId   
    siteConfig: {      
      netFrameworkVersion: 'v6.0'
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
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: instrumentationKey
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
          value: openAiKey
        }
      ]

      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}
output name string = functionApp.name
