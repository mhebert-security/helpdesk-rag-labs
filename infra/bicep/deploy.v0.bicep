// HELPDESK-RAG-PURPLE lab 00 baseline.
//
// Intentionally omits for v0: Entra ID auth on the App Service, NSG egress
// rules, APIM, and Content Safety. Each lands in a later lab.

@description('Azure region for every resource.')
param location string = 'eastus2'

@description('Name prefix. All resource names derive from this.')
param prefix string = 'raglab'

var tags = {
  lab: 'helpdesk-rag-purple'
  version: 'v0'
}

var openaiName = '${prefix}-openai'
var searchName = '${prefix}-search'
var storageName = '${prefix}storage'
var vaultName = '${prefix}-kv'
var planName = '${prefix}-plan'
var appName = '${prefix}-app'
var workspaceName = '${prefix}-log'
var appInsightsName = '${prefix}-appi'

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: tags
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logWorkspace.id
  }
}

module openai 'modules/openai/main.bicep' = {
  name: 'openai'
  params: {
    location: location
    name: openaiName
    tags: tags
  }
}

module search 'modules/search/main.bicep' = {
  name: 'search'
  params: {
    location: location
    name: searchName
    tags: tags
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  parent: storage
  name: 'default'
}

resource corpusContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobService
  name: 'corpus'
}

resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: vaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

resource plan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: planName
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  properties: {
    reserved: true
  }
}

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  kind: 'app,linux'
  tags: tags
  properties: {
    serverFarmId: plan.id
    reserved: true
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      appSettings: [
        { name: 'AZURE_OPENAI_ENDPOINT', value: openai.outputs.endpoint }
        { name: 'AZURE_OPENAI_DEPLOYMENT', value: openai.outputs.deploymentName }
        { name: 'AZURE_SEARCH_ENDPOINT', value: search.outputs.endpoint }
        { name: 'AZURE_SEARCH_INDEX', value: 'helpdesk-corpus' }
      ]
    }
  }
}

// Store service keys in Key Vault (good habit even in v0).
resource openaiKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: vault
  name: 'openai-key'
  properties: {
    value: openai.outputs.key
  }
}

resource searchKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: vault
  name: 'search-key'
  properties: {
    value: search.outputs.adminKey
  }
}

output appHostname string = app.properties.defaultHostName
output openaiEndpoint string = openai.outputs.endpoint
output searchEndpoint string = search.outputs.endpoint
