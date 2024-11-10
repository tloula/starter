@description('Deployes the backend resources for the Armedis application')
param location string = resourceGroup().location
param secondaryLocation string = 'eastus2'
param name string = 'armedis'
param apiContainerName string = 'api'
param teamEntraGroupObjectId string = '78e27676-d07b-4509-9bf5-4b46d8ed450e'
// param containerNames array = []

@secure()
param postgresAdminPassword string = newGuid()

// Telemetry

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'  // Pay-As-You-Go
    }
  }
  tags: {
    creator: 'bicep'
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    IngestionMode: 'LogAnalytics'
    WorkspaceResourceId: logAnalytics.id
  }
  tags: {
    creator: 'bicep'
  }
}

// Containers

resource containerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-containers'
  location: location
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
  }
  tags: {
    creator: 'bicep'
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: apiContainerName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Single'
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: containerIdentity.id
        }
      ]
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        allowInsecure: true
        ipSecurityRestrictions: null
        corsPolicy: null
      }
    }
    template: {
      containers: [
        {
          image: 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
          name: apiContainerName
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/liveness'
                port: 80
                scheme: 'HTTP'
              }
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${containerIdentity.id}': {}
    }
  }
}

// Configuration Stores

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: name
  location: secondaryLocation
  sku: {
    name: 'free'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    accessPolicies: []
    enableRbacAuthorization: true
  }
}

resource keyVaultSecretAppInsights 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'azure-application-insights-connection-string'
  properties: {
    value: appInsights.properties.ConnectionString
  }
}

resource keyVaultSecretPosgresPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'azure-cosmosdb-postgresql-password'
  properties: {
    value: postgresAdminPassword
  }
}

resource keyVaultSecretPosgresCoordinatorUrl 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'azure-cosmosdb-postgresql-coordinator-url'
  properties: {
    value: cosmosDbPostgreSql.properties.serverNames[0].fullyQualifiedDomainName
  }
}

// Data Stores

resource cosmosDbPostgreSql 'Microsoft.DBforPostgreSQL/serverGroupsv2@2023-03-02-preview' = {
  name: name
  location: location
  properties: {
    databaseName: name
    administratorLoginPassword: postgresAdminPassword
    enableHa: false
    enableGeoBackup: false
    postgresqlVersion: '16'
    coordinatorVCores: 1
    coordinatorStorageQuotaInMb: 32768
    coordinatorServerEdition: 'BurstableMemoryOptimized'
    nodeCount: 0
    nodeVCores: 4
    nodeStorageQuotaInMb: 524288
    nodeServerEdition: 'MemoryOptimized'
    nodeEnablePublicIpAccess: true
    coordinatorEnablePublicIpAccess: true
  }
}

// resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
//   name: name
//   location: location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'StorageV2'
// }

// resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
//   name: 'default'
//   parent: storageAccount
// }

// resource containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = [for containerName in containerNames: {
//   parent: blobService
//   name: !empty(containerNames) ? '${toLower(containerName)}' : 'placeholder'
//   properties: {
//     publicAccess: 'None'
//     metadata: {}
//   }
// }]

// Role Assignments

resource roleAssignmentACR 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, name, containerRegistry.name, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: containerIdentity.properties.principalId
  }
}

resource roleAssignmentAppConfig 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, name, appConfig.name, 'appconfigurationdatareader')
  scope: appConfig
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071')
    principalId: containerIdentity.properties.principalId
  }
}

resource roleAssignmentKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, name, keyVault.name, 'keyvaultsecretsuser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: containerIdentity.properties.principalId
  }
}

resource roleAssignmentTMGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, name, teamEntraGroupObjectId, 'keyvaultadministrator')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: teamEntraGroupObjectId
  }
}
