metadata description = 'Creates an Azure Static Web Apps instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
param sku object = {
  name: 'Free'
  tier: 'Free'
}
param sqlServerLocation string
param sqlServerId string
@secure()
param repositoryUrl string
@secure()
param repositoryToken string
@secure()
param sqlConnectionString string

resource web 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: tags
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
  sku:sku
}
resource symbolicname 'Microsoft.Web/staticSites/databaseConnections@2022-09-01' = {
  name: 'default'
  parent: web
  properties: {
    connectionString: sqlConnectionString
    region: sqlServerLocation
    resourceId: sqlServerId
  }
}
