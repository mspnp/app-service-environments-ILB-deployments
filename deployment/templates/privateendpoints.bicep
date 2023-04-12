//param privateEndpoints_votingsbpe_name string = 'votingsbpe'

@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('Subscrpition ID')
param SubId string

@description('The name of the existing vnet to use.')
param vnetName string = 'ASE-VNETaimoczwhjiepc'

@description('The name of the existing subnet to use.')
param existingSubnetName string = 'jumpbox-subnet-aimoczwhjiepc'

@description('The name of the existing service bus namespace for creating the private endpoint.')
param existingServiceBusName string = 'votingservicebusaimoczwhjiepc'

@description('The name of the existing sql server namespace for creating the private endpoint.')
param existingSQLServerName string = 'sqlserveraimoczwhjiepc'

@description('The name of the existing cosmosdb namespace for creating the private endpoint.')
param existingCosmosDBName string = 'votingcosmos-aimoczwhjiepc'

@description('The name of the existing keyvault namespace for creating the private endpoint.')
param existingAKeyVaultName string = 'akeyvault-aimoczwhjiepc'

param namespaces_votingservicebusaimoczwhjiepc_externalid string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceBus/namespaces/${existingServiceBusName}'
param existingSQLServerNameExternalId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Sql/servers/${existingSQLServerName}'
param existingCosmosDBNameExternalId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${existingCosmosDBName}'
param existingAKeyVaultNameExternalId string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.KeyVault/vaults/${existingAKeyVaultName}'

var vnetId = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${vnetName}'
var subnetId = '${vnetId}/subnets/${existingSubnetName}'

var privateEndpointServiceBusName = 'votingprivateendpoint${uniqueString(resourceGroup().id)}'
var privateEndpointSQLServerName = 'votingprivateendpoint${uniqueString(resourceGroup().id)}'
var privateEndpointCosmosDbName = 'votingprivateendpoint${uniqueString(resourceGroup().id)}'
var privateEndpointKeyVaultName = 'votingprivateendpoint${uniqueString(resourceGroup().id)}'

var serviceBusFQDN = '${existingServiceBusName}.servicebus.windows.net'
var serviceBusPrivateEndpointName = 'votingservicebus${uniqueString(resourceGroup().id)}'

var sqlServerFQDN = '${existingSQLServerName}.database.windows.net'
var sqlServerPrivateEndpointName = 'votingsqlserver${uniqueString(resourceGroup().id)}'

var cosmosDBFQDN = '${existingCosmosDBName}.documents.azure.com'
var cosmosDBPrivateEndpointName = 'votingcosmosdb${uniqueString(resourceGroup().id)}'

var aKeyVaultFQDN = '${existingAKeyVaultName}.vault.azure.net'
var aKeyVaultPrivateEndpointName = 'votingakeyvault${uniqueString(resourceGroup().id)}'

resource privateEndpoint_ServiceBus 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointServiceBusName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: serviceBusPrivateEndpointName
        properties: {
          privateLinkServiceId: namespaces_votingservicebusaimoczwhjiepc_externalid
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpointServiceBusName}-nic'
    subnet: {
      id: subnetId
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: serviceBusFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
    ]
  }
}
resource privateEndpoint_SQLServer 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointSQLServerName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: sqlServerPrivateEndpointName
        properties: {
          privateLinkServiceId: existingSQLServerNameExternalId
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpointSQLServerName}-nic'
    subnet: {
      id: '${subnetId}/subnets/${existingSubnetName}'
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: sqlServerFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
    ]
  }
}
resource privateEndpoint_CosmosDb 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointCosmosDbName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: cosmosDBPrivateEndpointName
        properties: {
          privateLinkServiceId: existingCosmosDBNameExternalId
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpointCosmosDbName}-nic'
    subnet: {
      id: '${subnetId}/subnets/${existingSubnetName}'
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: cosmosDBFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
    ]
  }
}
resource privateEndpoint_KeyVault 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointKeyVaultName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: aKeyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: existingAKeyVaultNameExternalId
          groupIds: [
            'namespace'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
            actionsRequired: 'None'
          }
        }
      }

    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${privateEndpointKeyVaultName}-nic'
    subnet: {
      id: '${subnetId}/subnets/${existingSubnetName}'
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: aKeyVaultFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-01-01' existing = {
  name: vnetName
}

resource serviceBusPrivateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.${serviceBusFQDN}'
  location: 'global'
  properties: {}
  dependsOn: [vnet]
}

resource serviceBusPrivateDNSZoneRecord 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = {
  parent: serviceBusPrivateDNSZone
  name: '${serviceBusPrivateDNSZone.name}_privatelink.${serviceBusFQDN}'
  properties: {
    ttl: 3600
    cnameRecord: {
      cname: '${serviceBusFQDN}.'
    }
  }
}

resource serviceBusPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: serviceBusPrivateDNSZone
  name: '${serviceBusPrivateDNSZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
