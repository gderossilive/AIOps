param AKSname string
//param dataCollectionEndpointId string
param dataCollectionRuleId string

resource AKS 'Microsoft.ContainerService/managedClusters@2021-08-01' existing = {
  name: AKSname
}

resource DCRA_AKS 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'ContainerInsightsExtension'
  scope: AKS
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: dataCollectionRuleId
  }
}
