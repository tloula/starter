param location string
param projectName string
param containerName string
param logAnalytics resource 'Microsoft.OperationalInsights/workspaces@2021-06-01'

resource containerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${projectName}-containers'
  location: location
}

resource roleAssignmentACR 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, projectName, containerRegistry.name, 'acrpull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: containerIdentity.properties.principalId
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: projectName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: projectName
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
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerName
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
          name: containerName
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

output containerIdentity resource = containerIdentity
