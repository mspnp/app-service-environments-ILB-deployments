@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The name for the sql server admin user.')
param sqlAdminUserName string

@description('The password for the sql server admin user.')
@secure()
param sqlAdminPassword string

@description('The SID for the Microsoft Entra ID user to be the admin for the database server')
param sqlEntraIdAdminSid string

@description('True for high availability deployments, False otherwise.')
param zoneRedundant bool = false

var cosmosName = 'votingcosmos-${uniqueString(resourceGroup().id)}'
var cosmosDatabaseName = 'cacheDB'
var cosmosContainerName = 'cacheContainer'
var cosmosPartitionKeyPaths = [
  '/MessageType'
]
var sqlServerName = 'sqlserver${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'voting'
var serviceBusName = 'votingservicebus${uniqueString(resourceGroup().id)}'
var serviceBusQueueName = 'votingqueue'
var resourcesStorageAccountName = toLower('resources${uniqueString(resourceGroup().id)}')
var resourcesStorageAccountFunctionAppName = toLower('stfa${uniqueString(resourceGroup().id)}')
var resourcesContainerName = 'rscontainer'
var keyVaultName = 'akeyvault1-${uniqueString(resourceGroup().id)}'
 
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' = {
  name: cosmosName
  location: location
  tags: {
    defaultExperience: 'Core (SQL)'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    //ipRangeFilter: ''
    publicNetworkAccess: 'Disabled'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: true
    isVirtualNetworkFilterEnabled: true    
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
      maxIntervalInSeconds: 5
      maxStalenessPrefix: 100
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: zoneRedundant
      }
    ]
    capabilities: []
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2025-04-15' = {
  parent: cosmos
  name: cosmosDatabaseName
  properties: {
    resource: {
      id: cosmosDatabaseName
    }
    options: {
      throughput: 400
    }
  }
}

resource cosmosDatabaseContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2025-04-15' = {
  parent: cosmosDatabase
  name: cosmosContainerName
  properties: {
    options: {
      throughput: 400
    }
    resource: {
      id: cosmosContainerName
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/"_etag"/?'
          }
        ]
      }
      partitionKey: {
        paths: cosmosPartitionKeyPaths
        kind: 'Hash'
      }
    }
  }
}
 
resource sqlServer 'Microsoft.Sql/servers@2024-11-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUserName
    publicNetworkAccess: 'Disabled'
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlServerDatabase 'Microsoft.Sql/servers/databases@2024-11-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: (zoneRedundant ? 'BC_Gen5' : 'GP_Gen5')
    tier: (zoneRedundant ? 'BusinessCritical' : 'GeneralPurpose')
    family: 'Gen5'
    capacity: 2
  }
  //kind: 'v12.0,user,vcore'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: 1073741824
    zoneRedundant: zoneRedundant
  }
}

resource sqlServerAdmin 'Microsoft.Sql/servers/administrators@2024-11-01-preview' = {
  parent: sqlServer
  name: 'activeDirectory'
  //location: location
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'ADMIN'
    sid: sqlEntraIdAdminSid
    tenantId: subscription().tenantId
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []
    enableRbacAuthorization: true // Enables RBAC permission model
    publicNetworkAccess: 'disabled'
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId    
  }
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2025-05-01-preview' = {
  name: serviceBusName
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    zoneRedundant: zoneRedundant
  }
}

resource serviceBusListenerSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2025-05-01-preview' = {
  parent: serviceBus
  name: 'ListenerSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource serviceBusSenderSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2025-05-01-preview' = {
  parent: serviceBus
  name: 'SenderSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2025-05-01-preview' = {
  parent: serviceBus
  name: serviceBusQueueName
  //location: location
  properties: {
    lockDuration: 'PT1M'
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    defaultMessageTimeToLive: 'P10675199DT2H48M5.4775807S'
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    duplicateDetectionHistoryTimeWindow: 'PT10M'
    maxDeliveryCount: 10
    status: 'Active'
    autoDeleteOnIdle: 'P10675199DT2H48M5.4775807S'
    enablePartitioning: false
    enableExpress: false
  }
}

resource resourcesStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: resourcesStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: (zoneRedundant ? 'Standard_ZRS' : 'Standard_LRS')    
    //tier: 'Standard'
  }
  properties: {
    allowBlobPublicAccess: true
    accessTier: 'Hot'
  }
}

resource resourcesStorageAccountDefaultResourcesContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  name: '${resourcesStorageAccountName}/default/${resourcesContainerName}'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    resourcesStorageAccount
  ]
}

resource resourcesStorageAccountFunctionApp 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: resourcesStorageAccountFunctionAppName
  location: location
  kind: 'StorageV2'
  sku: {
    name: (zoneRedundant ? 'Standard_ZRS' : 'Standard_LRS')
  }
  properties: {
    allowBlobPublicAccess: false // Disable public access
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    allowSharedKeyAccess: false // Disable key-based access
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: [] // No IPs allowed unless explicitly added
      virtualNetworkRules: [] // No VNet access unless explicitly added
    }
  }
}


output cosmosDbName string = cosmosName
output sqlServerName string = sqlServerName
output sqlDatabaseName string = sqlDatabaseName
output resourcesStorageAccountName string = resourcesStorageAccountName
output resourcesStorageAccountFunctionAppName string = resourcesStorageAccountFunctionAppName
output resourcesContainerName string = resourcesContainerName
output keyVaultName string = keyVaultName
output serviceBusName string = serviceBusName
