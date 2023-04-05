//param privateEndpoints_votingsbpe_name string = 'votingsbpe'


@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('Subscrpition ID')
param SubId string

@description('The name of the existing vnet to use.')
param virtualNetworks_externalid string = 'ASE-VNETaimoczwhjiepc'

@description('The name of the existing subnet to use.')
param existingSubnetName string = 'jumpbox-subnet-aimoczwhjiepc'

@description('The name of the existing service bus namespace for creating the private endpoint.')
param existingServiceBusNamespace string = 'votingservicebusaimoczwhjiepc'

param namespaces_votingservicebusaimoczwhjiepc_externalid string = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceBus/namespaces/${existingServiceBusNamespace}'

var serviceBusFQDN = '${existingServiceBusNamespace}.servicebus.windows.net'
var vnetId = '/subscriptions/${SubId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworks_externalid}'
var serviceBusPrivateEndpointName = 'votingservicebus${uniqueString(resourceGroup().id)}'


resource privateEndpoints_votingsbpe_name_resource 'Microsoft.Network/privateEndpoints@2022-09-01' = {
  name: serviceBusPrivateEndpointName
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
    ]
    manualPrivateLinkServiceConnections: []
    customNetworkInterfaceName: '${serviceBusPrivateEndpointName}-nic'
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
    ]
  }
}
