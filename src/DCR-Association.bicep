param VMName string
//param dataCollectionEndpointId string
param dataCollectionRuleId string
param Seed string

resource VM 'Microsoft.HybridCompute/machines@2023-10-03-preview' existing = {
  name: VMName
}

resource DCRA 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'DCRA-${Seed}'
  scope: VM
  properties: {
//    dataCollectionEndpointId: dataCollectionEndpointId
    dataCollectionRuleId: dataCollectionRuleId
  }
}
