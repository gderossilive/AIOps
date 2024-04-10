param WorkspaceName string
param location string
param Seed string
param VMlist array
param AKSlist array

resource LAW 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: WorkspaceName
}

resource DCR_VMInsights 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'DCR-VM-${Seed}'
  location: location
  properties: {
//    dataCollectionEndpointId: DCE.id
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers:[
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
      extensions: [
        {
          name: 'DependencyAgentDataSource'
          streams: [
            'Microsoft-ServiceMap'
          ]
          extensionName: 'DependencyAgent'
          extensionSettings: {}

        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: LAW.id
          name: WorkspaceName
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          WorkspaceName
        ]
      }
      {
        streams: [
          'Microsoft-ServiceMap'
        ]
        destinations: [
          WorkspaceName
        ]
      }
    ]
  }
}

resource DCR_ContainerInsights 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: 'DCR-AKS-${Seed}'
  location: location
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: []
      extensions: [
        {
          streams: [
            'Microsoft-ContainerInsights-Group-Default'
          ]
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Off'
              enableContainerLogV2: true
            }
          }
          name: 'ContainerInsightsExtension'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: LAW.id
          name: 'ciworkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerInsights-Group-Default'
        ]
        destinations: [
          'ciworkspace'
        ]
      }
    ]
  }
}

module DCR_VM_Association 'DCR-VM-Association.bicep' = [for VMName in VMlist:{
  name: 'DCR-${VMName}-${Seed}'
  params: {
    VMName: VMName
//    dataCollectionEndpointId: DCR_VMInsights.id
    dataCollectionRuleId: DCR_VMInsights.id
    Seed: Seed
  }
}]

module DCR_AKS_Association 'DCR-AKS-Association.bicep' = [for AKSName in AKSlist:{
  name: 'DCRA-${AKSName}-${Seed}'
  params: {
    AKSname: AKSName
//    dataCollectionEndpointId: DCR_VMInsights.id
    dataCollectionRuleId: DCR_ContainerInsights.id
  }
}]
