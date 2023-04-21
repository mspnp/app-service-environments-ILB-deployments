@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where redis will be connected.')
param vnetName string

@description('The ip address prefix REDIS will use.')
param redisSubnetAddressPrefix string

@description('The ASE name where to host the applications')
param aseName string

@description('DNS suffix where the app will be deployed')
param aseDnsSuffix string

@description('The name of the key vault name')
param keyVaultName string

@description('The cosmos DB name')
param cosmosDbName string

@description('The name for the sql server')
param sqlServerName string

@description('The name for the sql database')
param sqlDatabaseName string

@description('The name for the log analytics workspace')
param logAnalyticsWorkspace string = '${uniqueString(resourceGroup().id)}la'

@description('The availability zone to deploy. Valid values are: 1, 2 or 3. Use empty to not use zones.')
param zone string = ''

var instanceIndex = (empty(zone) ? '0' : zone)
var redisName_var = 'REDIS-${uniqueString(resourceGroup().id)}-${instanceIndex}'
var redisSubnetName = 'redis-subnet-${uniqueString(resourceGroup().id)}-${instanceIndex}'
var redisSubnetId = vnetName_redisSubnetName.id
var redisNSGName_var = '${vnetName}-REDIS-${instanceIndex}-NSG'
var redisSecretName = 'RedisConnectionString${instanceIndex}'
var cosmosKeySecretName = 'CosmosKey'
var serviceBusListenerConnectionStringSecretName = 'ServiceBusListenerConnectionString'
var serviceBusSenderConnectionStringSecretName = 'ServiceBusSenderConnectionString'
var votingApiName_var = 'votingapiapp-${instanceIndex}-${uniqueString(resourceGroup().id)}'
var votingWebName_var = 'votingwebapp-${instanceIndex}-${uniqueString(resourceGroup().id)}'
var testWebName_var = 'testwebapp-${instanceIndex}-${uniqueString(resourceGroup().id)}'
var votingFunctionName_var = 'votingfuncapp-${instanceIndex}-${uniqueString(resourceGroup().id)}'
var votingApiPlanName_var = '${votingApiName_var}-plan'
var votingWebPlanName_var = '${votingWebName_var}-plan'
var testWebPlanName_var = '${testWebName_var}-plan'
var votingFunctionPlanName_var = '${votingFunctionName_var}-plan'
var aseId = resourceId('Microsoft.Web/hostingEnvironments', aseName)

resource redisNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: redisNSGName_var
  location: location
  tags: {
    displayName: redisNSGName_var
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

resource vnetName_redisSubnetName 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${redisSubnetName}'
  //location: location
  properties: {
    addressPrefix: redisSubnetAddressPrefix
    networkSecurityGroup: {
      id: redisNSGName.id
    }
  }
}

resource redisName 'Microsoft.Cache/Redis@2022-06-01' = {
  name: redisName_var
  location: location
  zones: (empty(zone) ? json('null') : array(zone))
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


resource keyvault_parent 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}


resource keyVaultName_redisSecretName 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyvault_parent
  name: redisSecretName
  properties: {
    value: '${redisName_var}.redis.cache.windows.net:6380,abortConnect=false,ssl=true,password=${listKeys(redisName.id, '2015-08-01').primaryKey}'
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspace
  location: location  
}


resource votingFunctionName 'Microsoft.Insights/components@2020-02-02' = {
  name: votingFunctionName_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'AppServiceEnablementCreate'
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingApiName 'Microsoft.Insights/components@2020-02-02' = {
  name: votingApiName_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingWebName 'Microsoft.Insights/components@2020-02-02' = {
  name: votingWebName_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource testWebName 'Microsoft.Insights/components@2020-02-02' = {
  name: testWebName_var
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    HockeyAppId: ''
    WorkspaceResourceId: logAnalytics.id
  }
}

resource votingFunctionPlanName 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingFunctionPlanName_var
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
      id:aseId
    }
  }
}

resource votingApiPlanName 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingApiPlanName_var
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
      id:aseId
    }
  }
}

resource votingWebPlanName 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: votingWebPlanName_var
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
      id:aseId
    }
  }
}

resource testWebPlanName 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: testWebPlanName_var
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
      id:aseId
    }
  }
}

resource Microsoft_Web_sites_votingFunctionName 'Microsoft.Web/sites@2022-03-01' = {
  name: votingFunctionName_var
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: votingFunctionName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingFunctionPlanName.id
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingFunctionName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${reference(votingFunctionName.id, '2020-02-02').InstrumentationKey}'
        }
        {
          name: 'SERVICEBUS_CONNECTION_STRING'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${serviceBusListenerConnectionStringSecretName})'
        }
        {
          name: 'sqldb_connection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
      ]
    }
  }
}

resource Microsoft_Web_sites_votingApiName 'Microsoft.Web/sites@2022-03-01' = {
  name: votingApiName_var
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: votingApiName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingApiPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingApiName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(votingApiName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:SqlDbConnection'
          value: 'Server=${sqlServerName}.database.windows.net,1433;Database=${sqlDatabaseName};'
        }
      ]
    }
  }
}

resource Microsoft_Web_sites_votingWebName 'Microsoft.Web/sites@2022-03-01' = {
  name: votingWebName_var
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: votingWebPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(votingWebName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:sbConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${serviceBusSenderConnectionStringSecretName})'
          
        }
        {
          name: 'ConnectionStrings:VotingDataAPIBaseUri'
          value: 'https://${Microsoft_Web_sites_votingApiName.properties.hostNames[0]}'
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(votingWebName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ConnectionStrings:RedisConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${keyVaultName_redisSecretName.name})'
        }
        {
          name: 'ConnectionStrings:queueName'
          value: 'votingqueue'
        }
        {
          name: 'ConnectionStrings:CosmosUri'
          value: 'https://${cosmosDbName}.documents.azure.com:443/'
        }
        {
          name: 'ConnectionStrings:CosmosKey'
          value: '@Microsoft.KeyVault(SecretUri=https://${keyVaultName}.vault.azure.net/secrets/${cosmosKeySecretName})'
        }
      ]
    }
  }
}

resource Microsoft_Web_sites_testWebName 'Microsoft.Web/sites@2022-03-01' = {
  name: testWebName_var
  location: location
  kind: 'app'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    //name: testWebName_var
    hostingEnvironmentProfile: {
      id:aseId
    }
    serverFarmId: testWebPlanName.id
    siteConfig: {
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(testWebName.id, '2020-02-02').InstrumentationKey
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(testWebName.id, '2020-02-02').InstrumentationKey
        }
      ]
    }
  }
}

resource keyVault_WebAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2022-07-01' = {
  parent: keyvault_parent
  name: 'add'
  properties: {
    accessPolicies: [
      {
        objectId: Microsoft_Web_sites_votingFunctionName.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: Microsoft_Web_sites_votingWebName.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: Microsoft_Web_sites_votingApiName.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: Microsoft_Web_sites_testWebName.identity.principalId
        permissions: {
          secrets: ['get','list']
          keys: ['get','list']
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

output redisName string = redisName_var
output redisSubnetId string = redisSubnetId
output redisSubnetName string = redisSubnetName
output votingWebName string = votingWebName_var
output testWebName string = testWebName_var
output votingAppUrl string = '${votingWebName_var}.${aseDnsSuffix}'
output testAppUrl string = '${testWebName_var}.${aseDnsSuffix}'
output votingApiName string = votingApiName_var
output votingFunctionName string = votingFunctionName_var
output votingWebAppIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingWebName_var}', '2022-03-01', 'Full').identity.principalId
output votingApiIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingApiName_var}', '2022-03-01', 'Full').identity.principalId
output votingCounterFunctionIdentityPrincipalId string = reference('Microsoft.Web/sites/${votingFunctionName_var}', '2022-03-01', 'Full').identity.principalId
