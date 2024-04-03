@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param OpenAIName string = 'OpenAI-${uniqueString(resourceGroup().id, newGuid())}'
param OpenAIdeploymentName string = 'OAIDeploy-${newGuid()}'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'S0'
])
param sku string = 'S0'
param Seed string
param KVname string
@secure()
param SPsecret string

resource OpenAIservice 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: 'OpenAI-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: sku
  }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: OpenAIName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

resource OpenAIdeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  name: OpenAIdeploymentName
  parent: OpenAIservice
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0301'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: 60
    raiPolicyName: 'Microsoft.Default'
  }
}

resource KV 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: KVname
}

resource SPsec 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' =  {
  name: 'SP-Secret'
  parent: KV
  properties: {
    value: SPsecret
  }
}

resource OpenAIsec 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' =  {
  name: 'API-Key'
  parent: KV
  properties: {
    value: OpenAIservice.listKeys().key1
  }
}

output OpenAIserviceName string = OpenAIservice.name
output OpenAIdeploymentName string = OpenAIdeployment.name
