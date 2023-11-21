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
param sqlConnectionString string

resource web 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
  sku: sku
}

resource symbolicname 'Microsoft.Web/staticSites/databaseConnections@2022-09-01' = {
  parent: web
  name: 'default'
  properties: {
    connectionString: sqlConnectionString
    region: sqlServerLocation
    resourceId: sqlServerId
  }
}

output name string = web.name
output uri string = 'https://${web.properties.defaultHostname}'
