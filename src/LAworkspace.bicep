param WorkspaceName string
param publicNetworkAccess string

resource workSpace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: WorkspaceName  
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    publicNetworkAccessForIngestion: publicNetworkAccess
    publicNetworkAccessForQuery: 'Enabled'
  }
}

/*
resource VmInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${workSpace.name})'
  location: resourceGroup().location
  properties: {
    workspaceResourceId: workSpace.id
  }
  plan: {
    name: 'VMInsights(${workSpace.name})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}

resource Security 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'Security(${workSpace.name})'
  location: resourceGroup().location
  properties: {
    workspaceResourceId: workSpace.id
  }
  plan: {
    name: workSpace.name
    product: 'OMSGallery/Security'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}
*/
output Id string = workSpace.id
