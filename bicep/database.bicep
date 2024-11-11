param location string
param projectName string

@secure()
param postgresAdminPassword string

resource cosmosDbPostgreSql 'Microsoft.DBforPostgreSQL/serverGroupsv2@2023-03-02-preview' = {
  name: projectName
  location: location
  properties: {
    databaseName: projectName
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

output cosmosDbPostgreSqlCoordinatorUrl string = cosmosDbPostgreSql.properties.serverNames[0].fullyQualifiedDomainName
