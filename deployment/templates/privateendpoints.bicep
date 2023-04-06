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
var privateEndpointName = 'votingprivateendpoint${uniqueString(resourceGroup().id)}'

var serviceBusFQDN = '${existingServiceBusName}.servicebus.windows.net'
var serviceBusPrivateEndpointName = 'votingservicebus${uniqueString(resourceGroup().id)}'

var sqlServerFQDN = '${existingSQLServerName}.database.windows.net'
var sqlServerPrivateEndpointName = 'votingsqlserver${uniqueString(resourceGroup().id)}'

var cosmosDBFQDN = '${existingCosmosDBName}.documents.azure.com'
var cosmosDBPrivateEndpointName = 'votingcosmosdb${uniqueString(resourceGroup().id)}'

var aKeyVaultFQDN = '${existingAKeyVaultName}.vault.azure.net'
var aKeyVaultPrivateEndpointName = 'votingakeyvault${uniqueString(resourceGroup().id)}'


resource privateEndpoints_votingsbpe_name_resource 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: serviceBusPrivateEndpointName
        //id: '${privateEndpoints_votingsbpe_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_votingsbpe_name}'
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
      {
        name: sqlServerPrivateEndpointName
        //id: '${privateEndpoints_votingsbpe_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_votingsbpe_name}'
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
      {
        name: cosmosDBPrivateEndpointName
        //id: '${privateEndpoints_votingsbpe_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_votingsbpe_name}'
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
      {
        name: aKeyVaultPrivateEndpointName
        //id: '${privateEndpoints_votingsbpe_name_resource.id}/privateLinkServiceConnections/${privateEndpoints_votingsbpe_name}'
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
    customNetworkInterfaceName: '${privateEndpointName}-nic'
    subnet: {
      id: '${vnetId}/subnets/${existingSubnetName}'
    }
    ipConfigurations: []
    customDnsConfigs: [
      {
        fqdn: serviceBusFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
      {
        fqdn: sqlServerFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
      {
        fqdn: cosmosDBFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
      {
        fqdn: aKeyVaultFQDN
        ipAddresses: [
          '10.0.250.5' //TODO: get the IP address of the service bus
        ]
      }
    ]
  }
}
