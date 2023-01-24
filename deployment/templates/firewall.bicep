@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location
param vnetName string

@description('The ip prefix the firewall will use.')
param firewallSubnetPrefix string

var firewallSubnetName = 'AzureFirewallSubnet'
var firewallPublicIpName_var = 'firewallIp-${uniqueString(resourceGroup().id)}'
var firewallName_var = 'firewall-${uniqueString(resourceGroup().id)}'

/*resource vnetRouteName_resource 'Microsoft.Network/routeTables@2019-11-01' = {
  name: vnetRouteName
  location: location
  tags: {
    displayName: 'UDR - Subnet'
  }
  properties: {
    routes: concat(aseManagementIpRoutes, array(json('{ "name": "Firewall", "properties": { "addressPrefix": "0.0.0.0/0", "nextHopType": "VirtualAppliance", "nextHopIpAddress": "${reference('Microsoft.Network/azureFirewalls/${firewallName_var}', '2019-09-01', 'Full').properties.ipConfigurations[0].properties.privateIPAddress}" } }')))
  }
  dependsOn: [
    firewallName
  ]
}

*/

resource vnetName_firewallSubnetName 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${firewallSubnetName}'
  properties: {
    addressPrefix: firewallSubnetPrefix
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.KeyVault'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.ServiceBus'
        locations: [
          location
        ]
      }
      {
        service: 'Microsoft.Sql'
        locations: [
          location
        ]
      }
    ]
  }
}

resource firewallPublicIpName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  location: location
  name: firewallPublicIpName_var
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource firewallName 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: firewallName_var
  location: location
  properties: {
    threatIntelMode: 'Alert'
    ipConfigurations: [
      {
        name: 'clusterIpConfig'
        properties: {
          publicIPAddress: {
            id: firewallPublicIpName.id
          }
          subnet: {
            id: vnetName_firewallSubnetName.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'Time'
        properties: {
          priority: 300
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'NTP'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '123'
              ]
            }
            {
              name: 'Triage'
              protocols: [
                'Any'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '12000'
              ]
            }
          ]
        }
      }
      {
        name: 'AzureMonitor'
        properties: {
          priority: 500
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AzureMonitor'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                'AzureMonitor'
              ]
              destinationPorts: [
                '80'
                '443'
              ]
            }
          ]
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'AppServiceEnvironment'
        properties: {
          priority: 500
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'AppServiceEnvironment'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: [
                'AppServiceEnvironment'
                'WindowsUpdate'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

output firewallSubnetName string = firewallSubnetName
