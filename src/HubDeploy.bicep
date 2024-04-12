targetScope = 'resourceGroup'
// General
param location string = resourceGroup().location
param Seed string
param MyObjectId string
@secure()
param adminPassword string

// Virtual Network
param HubVnetName string 
param HubVnetAddressPrefix string 
param PEsubnetName string
param PEsubnetAddressPrefix string
param DMZsubnetName string
param DMZsubnetAddressPrefix string
param BastionSubnetAddressPrefix string
param FirewallSubnetAddressPrefix string
param FirewallManagementSubnetAddressPrefix string
param GatewaySubnetAddressPrefix string
param BastionPublicIpName string
param BastionHostName string

var KVname = 'KV-${Seed}'


// Hub Virtual Network Deploy
resource HubVNet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: HubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        HubVnetAddressPrefix
      ]
    }
    dhcpOptions: { dnsServers: null}
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: BastionSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup:  null
        }
      }
      {
        name: PEsubnetName
        properties: {
          addressPrefix: PEsubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup:  null
          routeTable: null
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: FirewallSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: FirewallManagementSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: GatewaySubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: null
        }
      }
      {
        name: DMZsubnetName
        properties: {
          addressPrefix: DMZsubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: null
        }
      }
    ]
  }
}

module KV './KV.bicep' = {
  name: KVname
  params: {
    keyVaultName: KVname
    objectId: MyObjectId
    location: location
    principalId: MyObjectId
    Seed: Seed
  }
}

resource adminPsswd 'Microsoft.KeyVault/vaults/secrets@2021-04-01-preview' =  {
  dependsOn: [
    KV
  ]
  name: '${KVname}/adminPassword'
  properties: {
    value: adminPassword
  }
}

resource publicIpAddressForBastion 'Microsoft.Network/publicIpAddresses@2020-08-01' = {
  name: BastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' =  {
  name: BastionHostName
  dependsOn: [
    HubVNet
  ]
  location: location
  sku:{
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: HubVNet.properties.subnets[0].id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

output HubVnetName string = HubVnetName
output PEsubnetName string = PEsubnetName
output KvName string =  KVname
output KV object = KV
