targetScope='subscription'
// General
param location string 
param Seed string
param MyObjectId string
@secure()
param adminPassword string

// Resource Group
param HubRgName string = '${Seed}-Demo'

// Virtual Network
param HubVnetName string = 'VNet-${Seed}'
param HubVnetAddressPrefix string 
param PEsubnetName string = 'PE-Subnet'
param PEsubnetAddressPrefix string
param DMZsubnetName string = 'DMZ-Subnet'
param DMZsubnetAddressPrefix string
param BastionSubnetAddressPrefix string
param FirewallSubnetAddressPrefix string
param FirewallManagementSubnetAddressPrefix string
param GatewaySubnetAddressPrefix string
param BastionHostName string = 'Bastion-${Seed}'
param BastionPublicIpName string = 'BastionPublicIp-${Seed}'

param WinCommand string = ''
param LinCommand string = ''
param LinNum int = 0
param WinNum int = 0
param WinVMname string = 'WinVM-${Seed}'
param LinVMname string = 'LinVM-${Seed}'
param CustomDnsServer string =''
param rnd string = substring(uniqueString(utcNow()),0,5)
param vmsize string = 'Standard_B2ms'

param WorskspaceName string = 'LA-${Seed}'
param publicNetworkAccess string = 'Enabled'

param KVname string = 'KV-${Seed}'
param SSHPublickey string


// Hub Resource Group Deploy
resource HubRG 'Microsoft.Resources/resourceGroups@2021-01-01' existing = {
  name: HubRgName
}

// Hub Virtual Network Deploy
module HubDeploy 'src/HubDeploy.bicep' = {
  name: 'HubVnet'
  scope: HubRG
  params: {
    location: location
    Seed: Seed
    MyObjectId: MyObjectId
    adminPassword: adminPassword
    HubVnetName: HubVnetName
    BastionSubnetAddressPrefix: BastionSubnetAddressPrefix
    FirewallSubnetAddressPrefix: FirewallSubnetAddressPrefix
    FirewallManagementSubnetAddressPrefix: FirewallManagementSubnetAddressPrefix
    GatewaySubnetAddressPrefix: GatewaySubnetAddressPrefix
    HubVnetAddressPrefix: HubVnetAddressPrefix
    PEsubnetAddressPrefix: PEsubnetAddressPrefix
    PEsubnetName: PEsubnetName
    DMZsubnetAddressPrefix: DMZsubnetAddressPrefix
    DMZsubnetName: DMZsubnetName
    BastionHostName: BastionHostName
    BastionPublicIpName: BastionPublicIpName
  }
 }

 module LAW './src/LAworkspace.bicep' ={
  dependsOn: [HubDeploy]
  name: WorskspaceName
  scope: HubRG
  params: {
    WorkspaceName: WorskspaceName
    publicNetworkAccess : publicNetworkAccess
  }
}
 
module WindowsVM 'src/AzureVM.bicep' = [for i in range(1, WinNum): {
  dependsOn: [HubDeploy]
  name: 'WindowsVM-${Seed}-${rnd}-${i}'
  scope: HubRG
  params: {
    vmName: 'DC-${i}'
    adminPassword: adminPassword   
    virtualNetworkName: HubVnetName
    subnetName: DMZsubnetName
    location: location
    Command: WinCommand
    CustomDnsServer: CustomDnsServer
    vmSize: vmsize
    Publisher: 'MicrosoftWindowsServer'
    Offer: 'WindowsServer'
    Sku: '2022-Datacenter'
    Version: 'latest'
  }
}]

module LinuxVM 'src/AzureVM.bicep' = [for i in range(1, LinNum): {
  dependsOn: [HubDeploy]
  name: 'LinuxVM-${Seed}-${rnd}-${i}'
  scope: HubRG
  params: {
    vmName: '${LinVMname}-${i}'
    adminPassword: adminPassword
    virtualNetworkName: HubVnetName
    subnetName: DMZsubnetName
    location: location
    Command: LinCommand
    CustomDnsServer: CustomDnsServer
    vmSize: vmsize
    Publisher: 'Canonical'
    Offer: 'UbuntuServer'
    Sku: '18.04-LTS'
    Version: 'latest'
  }
}]

module AKS 'src/AKS.bicep' = {
  dependsOn: [LAW]
  name: 'AKS-${Seed}'
  scope: HubRG
  params: {
    location: location
    clusterName: 'AKS-${Seed}'
    LAWName: WorskspaceName
    Seed: Seed
    SSHPublicKey: SSHPublickey
  }
}

output WinVMsName array = [for i in range(0,WinNum):{
  name: WindowsVM[i].outputs.hostname
}]
output LinVMsName array = [for i in range(0,LinNum):{
  name: LinuxVM[i].outputs.hostname
}]

output HubVnetName string = HubVnetName
output PEsubnetName string = PEsubnetName
output KvName string =  KVname
output AKSName string = AKS.name
output laWname string = WorskspaceName
