param location string
param projectName string
param containerNames array

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: projectName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: 'default'
  parent: storageAccount
}

resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for containerName in containerNames: {
  parent: blobService
  name: !empty(containerNames) ? '${toLower(containerName)}' : 'placeholder'
  properties: {
    publicAccess: 'None'
    metadata: {}
  }
}]
