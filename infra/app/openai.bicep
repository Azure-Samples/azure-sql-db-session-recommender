metadata description = 'Creates an Azure Cognitive Services instance.'
param name string
param location string = resourceGroup().location
param tags object = {}
@description('The custom subdomain name used to access the API. Defaults to the value of the name parameter.')
param customSubDomainName string = name
param deployments array = []
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}
param keyVaultName string
param useKeyVault bool

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: account
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: 20
  }
}]

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (useKeyVault) {
  name: keyVaultName
}

resource openAIKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = if (useKeyVault) {
  parent: keyVault
  name: 'openAIKey'
  properties: {
    value: account.listKeys().key1
  }
}

output endpoint string = account.properties.endpoint
output id string = account.id
output name string = account.name
output openAIKeyName string = openAIKey.name
