@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where redis will be connected.')
param vnetName string

@description('The ip address prefix REDIS will use.')
param redisSubnetAddressPrefix string = '10.0.2.0/24'

@description('The ASE name where to host the applications')
param aseName string

@description('DNS suffix where the app will be deployed')
param aseDnsSuffix string

@description('The name of the key vault name')
param keyVaultName string

@description('The cosmos DB name')
param cosmosDbName string

@description('The namespace for the service bus')
param serviceBusNamespace string

@description('The name for the sql server')
param sqlServerName string

@description('The name for the sql database')
param sqlDatabaseName string

@description('The name for the storage account')
param storageAccountName string

@description('The name for the log analytics workspace')
param logAnalyticsWorkspace string = '${uniqueString(resourceGroup().id)}la'

@description('The availability zone to deploy. Valid values are: 1, 2 or 3. Use empty to not use zones.')
param zoneRedundant bool = false

var redisName = 'REDIS-${uniqueString(resourceGroup().id)}'
var redisSubnetName = 'redis-subnet-${uniqueString(resourceGroup().id)}'
var redisSubnetId = redisSubnet.id
var redisNSGName = '${vnetName}-REDIS-NSG'
var redisSecretName = 'RedisConnectionString'
var votingApiName = 'votingapiapp-${uniqueString(resourceGroup().id)}'
var votingWebName = 'votingwebapp-${uniqueString(resourceGroup().id)}'
var testWebName = 'testwebapp-${uniqueString(resourceGroup().id)}'
var votingFunctionName = 'votingfuncapp-${uniqueString(resourceGroup().id)}'
var votingApiPlanName = '${votingApiName}-plan'
var votingWebPlanName = '${votingWebName}-plan'
var testWebPlanName = '${testWebName}-plan'
var votingFunctionPlanName = '${votingFunctionName}-plan'
var aseId = resourceId('Microsoft.Web/hostingEnvironments', aseName)

var azureServiceBusDataSenderRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39'
) // Azure Service Bus Data Sender

var azureServiceBusDataReceiverRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0'
) //Azure Service Bus Data Receiver

var cosmosDBAccountReaderRole = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
) //Cosmos DB Account Reader

resource cosmosDatabaseAccount 'Microsoft.DocumentDB/databaseAccounts@2025-04-15' existing = {
  name: cosmosDbName
}
resource serviceBus 'Microsoft.ServiceBus/namespaces@2025-05-01-preview' existing = {
  name: serviceBusNamespace
}

resource redisNSG 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: redisNSGName
  location: location
  tags: {
    displayName: redisNSGName
  }
  properties: {
    securityRules: [
      {
        name: 'REDIS-inbound-vnet'
        properties: {
          description: 'Client communication inside vnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '13000-13999'
            '15000-15999'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-inbound-loadbalancer'
        properties: {
          description: 'Allow communication from Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-inbound-allow_internal-communication'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '6379'
            '6380'
            '8443'
            '10221-10231'
            '20226'
          ]
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Inbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_storage'
        properties: {
          description: 'Redis dependencies on Azure Storage/PKI (Internet)'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_DNS'
        properties: {
          description: 'Redis dependencies on DNS (Internet/VNet)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '53'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Outbound'
        }
      }
      {
        name: 'REDIS-outbound-allow_ports-within-subnet'
        properties: {
          description: 'Internal communications for Redis'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: redisSubnetAddressPrefix
          destinationAddressPrefix: redisSubnetAddressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource redisSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: '${vnetName}/${redisSubnetName}'
  properties: {
    addressPrefix: redisSubnetAddressPrefix
    defaultOutboundAccess: false
    networkSecurityGroup: {
      id: redisNSG.id
    }
  }
}

resource redis 'Microsoft.Cache/Redis@2024-11-01' = {
  name: redisName
  location: location
  zones: (zoneRedundant ? ['1', '2', '3'] : null)
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 3
    }
    enableNonSslPort: false
    subnetId: redisSubnetId
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource keyVaultRedisSecret 'Microsoft.KeyVault/vaults/secrets@2024-11-01' = {
  parent: keyVault
  name: redisSecretName
  properties: {
    value: '${redisName}.redis.cache.windows.net:6380,abortConnect=false,ssl=true,password=${listKeys(redis.id, '2015-08-01').primaryKey}'
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsWorkspace
  location: location
}

resource votingFunctionAppInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: votingFunctionName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'AppServiceEnablementCreate'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingApi 'Microsoft.Insights/components@2020-02-02' = {
  name: votingApiName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingWeb 'Microsoft.Insights/components@2020-02-02' = {
  name: votingWebName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource testWeb 'Microsoft.Insights/components@2020-02-02' = {
  name: testWebName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingFunctionPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: votingFunctionPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  //kind: 'functionapp'
  properties: {
    //name: votingFunctionPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id: aseId
    }
  }
}

resource votingApiPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: votingApiPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: votingApiPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id: aseId
    }
  }
}

resource votingWebPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: votingWebPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: votingWebPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id: aseId
    }
  }
}

resource testWebPlan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: testWebPlanName
  location: location
  sku: {
    name: 'I1V2'
    tier: 'IsolatedV2'
  }
  kind: 'app'
  properties: {
    //name: testWebPlanName_var
    perSiteScaling: false
    reserved: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    //hostingEnvironment: aseName
    hostingEnvironmentProfile: {
      id: aseId
    }
  }
}

resource votingStorage 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
}

resource votingFunction 'Microsoft.Web/sites@2024-11-01' = {
  name: votingFunctionName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id: aseId
    }
    serverFarmId: votingFunctionPlan.id
    siteConfig: {
      alwaysOn: true
      netFrameworkVersion: 'v9.0'
      use32BitWorkerProcess: false
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet-isolated'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: votingFunctionAppInsights.properties.InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${votingFunctionAppInsights.properties.InstrumentationKey}'
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBusNamespace}.servicebus.windows.net'
        }
        {
          name: 'sqldb_connection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
        {
          name: 'AzureWebJobsStorage'
          value: votingStorage.listKeys().keys[0].value
        }
      ]
    }
  }
}

resource serviceBusDataReceiverRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(votingWebApp.name, serviceBus.id, 'Azure Service Bus Data Receiver')
  scope: serviceBus
  properties: {
    roleDefinitionId: azureServiceBusDataReceiverRole
    principalId: votingFunction.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource votingApiApp 'Microsoft.Web/sites@2024-11-01' = {
  name: votingApiName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id: aseId
    }
    serverFarmId: votingApiPlan.id
    siteConfig: {
      netFrameworkVersion: 'v9.0'
      use32BitWorkerProcess: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: votingApi.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: votingApi.properties.InstrumentationKey
        }
        {
          name: 'ConnectionStrings:SqlDbConnection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
      ]
    }
  }
}

resource votingWebApp 'Microsoft.Web/sites@2024-11-01' = {
  name: votingWebName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id: aseId
    }
    serverFarmId: votingWebPlan.id
    siteConfig: {
      netFrameworkVersion: 'v9.0'
      use32BitWorkerProcess: false
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: votingWeb.properties.InstrumentationKey
        }
        {
          name: 'ConnectionStrings:sbNamespace'
          value: 'https://${serviceBusNamespace}.servicebus.windows.net/'
        }
        {
          name: 'ConnectionStrings:VotingDataAPIBaseUri'
          value: 'https://${votingApiApp.properties.hostNames[0]}'
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: votingWeb.properties.InstrumentationKey
        }
        {
          name: 'ConnectionStrings:RedisConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${keyVaultRedisSecret.name})'
        }
        {
          name: 'ConnectionStrings:queueName'
          value: 'votingqueue'
        }
        {
          name: 'ConnectionStrings:CosmosUri'
          value: 'https://${cosmosDbName}.documents.azure.com:443/'
        }
      ]
    }
  }
}

resource serviceBusSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(votingWebApp.name, serviceBus.id, 'Azure Service Bus Data Sender')
  scope: serviceBus
  properties: {
    roleDefinitionId: azureServiceBusDataSenderRole
    principalId: votingWebApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Assign Role to allow Read data from cosmos DB
resource cosmosDBDataReaderRoleAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(resourceGroup().id, cosmosDatabaseAccount.id, 'cosmosDBDataReaderRoleV2')
  parent: cosmosDatabaseAccount
  properties: {
    principalId: votingWebApp.identity.principalId
    roleDefinitionId: '/${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${cosmosDatabaseAccount.name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000001'
    scope: cosmosDatabaseAccount.id
  }
}

resource  cosmosDBAccountReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(votingWebApp.name, serviceBus.id, 'Cosmos DB Account Reader')
  scope: serviceBus
  properties: {
    roleDefinitionId: cosmosDBAccountReaderRole
    principalId: votingWebApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource testWebApp 'Microsoft.Web/sites@2024-11-01' = {
  name: testWebName
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id: aseId
    }
    serverFarmId: testWebPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: testWeb.properties.InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: testWeb.properties.InstrumentationKey
        }
      ]
    }
  }
}

resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2024-11-01' = {
  parent: keyVault
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: votingFunction.identity.principalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: votingWebApp.identity.principalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: votingApiApp.identity.principalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: testWebApp.identity.principalId
        permissions: {
          secrets: ['get', 'list']
          keys: ['get', 'list']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

output redisName string = redisName
output redisSubnetId string = redisSubnetId
output redisSubnetName string = redisSubnetName
output votingWebName string = votingWebName
output testWebName string = testWebName
output votingAppUrl string = '${votingWebName}.${aseDnsSuffix}'
output testAppUrl string = '${testWebName}.${aseDnsSuffix}'
output votingApiName string = votingApiName
output votingFunctionName string = votingFunctionName
output votingWebAppIdentityPrincipalId string = votingWebApp.identity.principalId
output votingApiIdentityPrincipalId string = votingApiApp.identity.principalId
output votingCounterFunctionIdentityPrincipalId string = votingFunction.identity.principalId
