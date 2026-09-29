// Azure OpenAI account with one gpt-4o chat deployment.
param location string
param name string
param deploymentName string = 'gpt-4o'
param modelVersion string = '2024-05-13'
param capacity int = 10
param tags object = {}

resource account 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  tags: tags
  properties: {
    customSubDomainName: name
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: account
  name: deploymentName
  sku: {
    name: 'Standard'
    capacity: capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: modelVersion
    }
  }
}

output endpoint string = 'https://${name}.openai.azure.com/'
output deploymentName string = deployment.name
output key string = listKeys(account.id, account.apiVersion).key1
