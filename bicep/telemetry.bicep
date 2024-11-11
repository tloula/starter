param location string
param projectName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: projectName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'  // Pay-As-You-Go
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: projectName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: logAnalytics.id
  }
}

output logAnalytics resource = logAnalytics
output appInsights resource = appInsights
