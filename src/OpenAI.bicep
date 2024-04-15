@description('That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)')
param OpenAIName string = 'OAISrv-${Seed}-${substring(uniqueString(resourceGroup().id, newGuid()),0,3)}'
param OpenAIdeploymentName string = 'OAIDeploy-${Seed}-${substring(uniqueString(resourceGroup().id, newGuid()),0,3)}'

@description('Location for all resources.')
param location string = 'swedencentral'

param ServiceName string = 'Standard'
param Capacity int = 50

@allowed([
  'S0'
])
param sku string = 'S0'
param format string = 'OpenAI'
param ModelName string = 'gpt-35-turbo'
param version string = '0613'

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
  sku: {
    name: ServiceName
    capacity: Capacity
  }
  properties: {
    model: {
      format: format
      name: ModelName
      version: version
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
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
output OpenAIName string = OpenAIName
