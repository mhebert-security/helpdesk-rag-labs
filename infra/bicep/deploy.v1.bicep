// HELPDESK-RAG-PURPLE baseline, v1.
//
// v1 replaces the Azure OpenAI account with an Azure AI Foundry hub, project,
// and DeepSeek-R1 serverless endpoint. Search, storage, Key Vault, the App
// Service plan, the App Service, Log Analytics, and App Insights are unchanged
// from v0. Entra ID auth, NSG egress, APIM, and Content Safety stay omitted.

@description('Azure region for every resource.')
param location string = 'eastus2'

@description('Name prefix. All resource names derive from this.')
param prefix string = 'raglab'

var tags = {
  lab: 'helpdesk-rag-purple'
  version: 'v1'
}

var hubName = '${prefix}-hub'
var projectName = '${prefix}-project'
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

// Azure AI Foundry: hub, project, and DeepSeek-R1 serverless endpoint.
resource hub 'Microsoft.MachineLearningServices/workspaces@2026-07-01' = {
  name: hubName
  location: location
  kind: 'Hub'
  tags: tags
  properties: {
    friendlyName: hubName
    publicNetworkAccess: 'Enabled'
  }
}

resource project 'Microsoft.MachineLearningServices/workspaces@2026-07-01' = {
  name: projectName
  location: location
  kind: 'Project'
  tags: tags
  properties: {
    friendlyName: projectName
    publicNetworkAccess: 'Enabled'
    workspaceHubConfig: {
      workspaceHubResourceId: hub.id
      defaultWorkspaceResourceGroup: resourceGroup().name
    }
  }
}

resource foundryEndpoint 'Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2026-07-01' = {
  parent: project
  name: 'DeepSeek-R1'
  location: location
  tags: tags
  properties: {
    modelSettings: {
      modelId: 'azureml://registries/azureml-deepseek/models/DeepSeek-R1/versions/1'
    }
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
        { name: 'AZURE_AI_FOUNDRY_ENDPOINT', value: foundryEndpoint.properties.scoringUri }
        { name: 'AZURE_AI_FOUNDRY_MODEL', value: 'DeepSeek-R1' }
        { name: 'AZURE_SEARCH_ENDPOINT', value: search.outputs.endpoint }
        { name: 'AZURE_SEARCH_INDEX', value: 'helpdesk-corpus' }
      ]
    }
  }
}

// Store service keys in Key Vault.
resource foundryKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: vault
  name: 'foundry-key'
  properties: {
    value: listKeys(foundryEndpoint.id, foundryEndpoint.apiVersion).primaryKey
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
output foundryEndpoint string = foundryEndpoint.properties.scoringUri
output foundryKeySecretUri string = foundryKeySecret.id
output searchEndpoint string = search.outputs.endpoint
