@description('Location for all resources.')
param location string = resourceGroup().location

param repositoryUrl string

@secure()
param repositoryToken string

@secure()
param sqlConnectionString string

@secure()
param openAIKey string

@secure()
param openAIEndpoint string

@description('Tags to assign to the resources, if needed')
param resourceTags object

var appName = 'session-recommender'
var appId = uniqueString(resourceGroup().id)

var staticWebAppName = '${appName}-${appId}'
var functionAppName = '${appName}-api-${appId}'
var hostingPlanName = '${appName}-plan-${appId}'
var applicationInsightsName = '${appName}-ai-${appId}'
var storageAccountName = '${appId}storage'

resource staticWebApp 'Microsoft.Web/staticSites@2022-09-01' = {
  name: staticWebAppName
  location: location
  tags: resourceTags
  properties: {
    repositoryUrl: repositoryUrl
    branch: 'main'
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: '/client'
      apiLocation: '/api'
      appArtifactLocation: '/dist'
    }
  }
  sku: {
    tier: 'Free'
    name: 'Free'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {
    supportsHttpsTrafficOnly: true
    defaultToOAuthAuthentication: true
  }
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id    
    siteConfig: {      
      netFrameworkVersion: 'v6.0'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
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
          value: applicationInsights.properties.InstrumentationKey
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

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}
