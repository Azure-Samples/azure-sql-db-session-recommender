param name string
param location string = resourceGroup().location
param repositoryUrl string
@secure()
param repositoryToken string
param resourceTags object

resource session_recommender_swa 'Microsoft.Web/staticSites@2022-09-01' = {
  name: name
  location: location
  tags: resourceTags
  properties: {
    repositoryUrl: repositoryUrl
    branch: 'main'
    repositoryToken: repositoryToken
    buildProperties: {
      appLocation: '/swa/client'
      apiLocation: ''
      appArtifactLocation: '/swa/dist'
    }
  }
  sku: {
    tier: 'Free'
    name: 'Free'
  }
}
