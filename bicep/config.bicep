param location string
param projectName string

param appInsights resource 'Microsoft.Insights/components@2020-02-02'
param containerIdentity resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31'
param teamEntraGroupObjectId string

@secure()
param postgresCoordinatorUrl string
@secure()
param postgresAdminPassword string
@secure()
param devEntraAppClientSecret string

resource appConfig 'Microsoft.AppConfiguration/configurationStores@2023-03-01' = {
  name: projectName
  location: 'eastus2'
  sku: {
    name: 'free'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: projectName
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
    value: postgresCoordinatorUrl
  }
}

resource keyVaultSecretDevAppSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'dev-aad-app-client-secret'
  properties: {
    value: devEntraAppClientSecret
  }
}

resource roleAssignmentAppConfig 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, projectName, appConfig.name, 'appconfigurationdatareader')
  scope: appConfig
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '516239f1-63e1-4d78-a4de-a74fb236a071')
    principalId: containerIdentity.properties.principalId
  }
}

resource roleAssignmentKeyVault 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, projectName, keyVault.name, 'keyvaultsecretsuser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: containerIdentity.properties.principalId
  }
}

resource roleAssignmentTMGroup 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, projectName, teamEntraGroupObjectId, 'keyvaultadministrator')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '00482a5a-887f-4fb3-b363-3b7fe8e74483')
    principalId: teamEntraGroupObjectId
  }
}

output appConfig resource = appConfig
output keyVault resource = keyVault
