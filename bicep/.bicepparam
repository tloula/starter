using 'main.bicep'

// Environment variables
param projectName = readEnvironmentVariable('PROJECT_NAME', '')
param containerName = readEnvironmentVariable('CONTAINER_NAME', '')
param location = readEnvironmentVariable('LOCATION', 'eastus')

param devEntraAppClientSecret = readEnvironmentVariable('AZURE_CLIENT_SECRET', '')
param teamEntraGroupObjectId = readEnvironmentVariable('TM_GROUP_OBJECT_ID', '')
