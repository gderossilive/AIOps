@description('The name of the Managed Cluster resource.')
param clusterName string = 'aks101cluster'

@description('The location of the Managed Cluster resource.')
param location string = resourceGroup().location

@description('Optional DNS prefix to use with hosted Kubernetes API server FQDN.')
param dnsPrefix string = '${clusterName}-dns'

@description('Disk size (in GB) to provision for each of the agent pool nodes. This value ranges from 0 to 1023. Specifying 0 will apply the default disk size for that agentVMSize.')
@minValue(0)
@maxValue(1023)
param osDiskSizeGB int = 128

@description('The number of nodes for the cluster.')
@minValue(1)
@maxValue(50)
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_B2ms'

@description('User name for the Linux Virtual Machines.')
param linuxAdminUsername string = 'gdradmin'

param LAWName string
param Seed string
param SSHPublicKey string

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: LAWName
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-04-02-preview' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: dnsPrefix
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: osDiskSizeGB
        count: agentCount
        vmSize: agentVMSize
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        minCount: 1
        maxCount: 3
        enableAutoScaling: true
        enableNodePublicIP: false
        securityProfile: {
          enableSecureBoot: false
          enableVTPM: false
          sshAccess: 'LocalUser'
        }
      }
    ]
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: SSHPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azurepolicy: {
        enabled: true
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: LAW.id
          useAADAuth: 'true'
        }
      }
    }
  }
}

output controlPlaneFQDN string = aks.properties.fqdn
