param name string
param location string = resourceGroup().location
param tags object = {}
param keyVaultName string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}
resource instrumentationKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'instrumentationKey'
  properties: {
    value: applicationInsights.properties.InstrumentationKey
  }
}
