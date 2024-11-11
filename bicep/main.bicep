@description('Deployes the backend resources for the Armedis application')

param location string
param projectName string
param containerName string
param teamEntraGroupObjectId string

@secure()
param devEntraAppClientSecret string

@secure()
param postgresAdminPassword string = newGuid()

// param containerNames array = []

targetScope = 'subscription'

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: projectName
  location: location
}

// Telemetry
module telemetry './telemetry.bicep' = {
  name: 'telemetry'
  scope: rg
  params: {
    location: location
    projectName: projectName
  }
}

// Compute
module compute 'compute.bicep' = {
  name: 'compute'
  scope: rg
  params: {
    location: location
    projectName: projectName
    containerName: containerName
    logAnalytics: telemetry.outputs.logAnalytics
  }
}

// Configuration Stores
module config 'config.bicep' = {
  name: 'config'
  scope: rg
  params: {
    location: location
    projectName: projectName
    devEntraAppClientSecret: devEntraAppClientSecret
    postgresAdminPassword: postgresAdminPassword
    postgresCoordinatorUrl: database.outputs.cosmosDbPostgreSqlCoordinatorUrl
    appInsights: telemetry.outputs.appInsights
    containerIdentity: compute.outputs.containerIdentity
    teamEntraGroupObjectId: teamEntraGroupObjectId
  }
}

// Database
module database 'database.bicep' = {
  name: 'database'
  scope: rg
  params: {
    location: location
    projectName: projectName
    postgresAdminPassword: postgresAdminPassword
  }
}
