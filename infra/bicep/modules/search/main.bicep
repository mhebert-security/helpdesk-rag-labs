// Azure AI Search service (Basic tier).
param location string
param name string
param tags object = {}

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: name
  location: location
  sku: {
    name: 'basic'
  }
  tags: tags
  properties: {
    hostingMode: 'default'
  }
}

output name string = search.name
output endpoint string = 'https://${name}.search.windows.net'
output adminKey string = listAdminKeys(search.id, search.apiVersion).primaryKey
