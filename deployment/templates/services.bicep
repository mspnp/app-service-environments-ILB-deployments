@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the gateway will be connected.')
param vnetName string

@description('The name for the sql server admin user.')
param sqlAdminUserName string

@description('The password for the sql server admin user.')
@secure()
param sqlAdminPassword string

@description('The SID for the AAD user to be the AD admin for the database server')
param sqlAadAdminSid string

@description('True for high availability deployments, False otherwise.')
param zoneRedundant bool = false

@description('Comma separated subnet names that can access the services.')
param allowedSubnetNames string

var cosmosName_var = 'votingcosmos-${uniqueString(resourceGroup().id)}'
var cosmosDatabaseName = 'cacheDB'
var cosmosContainerName = 'cacheContainer'
var cosmosPartitionKeyPaths = [
  '/MessageType'
]
var sqlServerName_var = 'sqlserver${uniqueString(resourceGroup().id)}'
var sqlDatabaseName = 'voting'
var serviceBusName_var = 'votingservicebus${uniqueString(resourceGroup().id)}'
var serviceBusQueue = 'votingqueue'
var resourcesStorageAccountName_var = toLower('resources${uniqueString(resourceGroup().id)}')
var resourcesContainerName = 'rscontainer'
var keyVaultName_var = 'akeyvault-${uniqueString(resourceGroup().id)}'
var allowedSubnetNamesArray = split(allowedSubnetNames, ',')
 
resource cosmosName 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: cosmosName_var
  location: location
  tags: {
    defaultExperience: 'Core (SQL)'
  }
  kind: 'GlobalDocumentDB'
  properties: {
    //ipRangeFilter: ''
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

resource cosmosName_cosmosDatabaseName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  parent: cosmosName
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

resource cosmosName_cosmosDatabaseName_cosmosContainerName 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-05-15' = {
  parent: cosmosName_cosmosDatabaseName
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
 
resource sqlServerName 'Microsoft.Sql/servers@2022-02-01-preview' = {
  name: sqlServerName_var
  location: location
  properties: {
    administratorLogin: sqlAdminUserName
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlServerName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2022-02-01-preview' = {
  parent: sqlServerName
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


resource sqlServerName_activeDirectory 'Microsoft.Sql/servers/administrators@2022-02-01-preview' = {
  parent: sqlServerName
  name: 'activeDirectory'
  //location: location
  properties: {
    administratorType: 'ActiveDirectory'
    login: 'ADMIN'
    sid: sqlAadAdminSid
    tenantId: subscription().tenantId
  }
}



resource keyVaultName 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName_var
  location: location
  properties: {
    accessPolicies: []
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId    
  }
}

resource keyVaultName_CosmosKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultName
  name: 'CosmosKey'
  properties: {
    value: listKeys(cosmosName.id, '2022-05-15').primaryMasterKey  //Microsoft.DocumentDB/databaseAccounts@2022-05-15
  }
}

resource keyVaultName_ServiceBusListenerConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultName
  name: 'ServiceBusListenerConnectionString'
  properties: {
    value: listKeys(serviceBusName_ListenerSharedAccessKey.id, '2021-11-01').primaryConnectionString   //Microsoft.ServiceBus/namespaces/AuthorizationRules
  }
}

resource keyVaultName_ServiceBusSenderConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVaultName
  name: 'ServiceBusSenderConnectionString'
  properties: {
    value: listKeys(serviceBusName_SenderSharedAccessKey.id, '2021-11-01').primaryConnectionString   //Microsoft.ServiceBus/namespaces/AuthorizationRules
  }
}

resource serviceBusName 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusName_var
  location: location
  sku: {
    name: 'Premium'
    tier: 'Premium'
    capacity: 1
  }
  properties: {
    zoneRedundant: zoneRedundant
  }
}

resource serviceBusName_ListenerSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBusName
  name: 'ListenerSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Listen'
    ]
  }
}

resource serviceBusName_SenderSharedAccessKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2022-01-01-preview' = {
  parent: serviceBusName
  name: 'SenderSharedAccessKey'
  //location: location
  properties: {
    rights: [
      'Send'
    ]
  }
}

resource serviceBusName_serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2022-01-01-preview' = {
  parent: serviceBusName
  name: serviceBusQueue
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

resource resourcesStorageAccountName 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: resourcesStorageAccountName_var
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


resource resourcesStorageAccountName_default_resourcesContainerName 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-09-01' = {
  name: '${resourcesStorageAccountName_var}/default/${resourcesContainerName}'
  properties: {
    publicAccess: 'Blob'
  }
  dependsOn: [
    resourcesStorageAccountName
  ]
}

output cosmosDbName string = cosmosName_var
output sqlServerName string = sqlServerName_var
output sqlDatabaseName string = sqlDatabaseName
output resourcesStorageAccountName string = resourcesStorageAccountName_var
output resourcesContainerName string = resourcesContainerName
output keyVaultName string = keyVaultName_var
