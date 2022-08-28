@description('The vnet name of the ASE vnet.')
param vnetName string

@description('The name of the zone. Must match the DNS prefix of the ILB ASE.')
param zoneName string

@description('The IP address of the ILB.')
param ipAddress string

var vnetId = resourceId('Microsoft.Network/virtualNetworks', vnetName)

resource zoneName_resource 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: zoneName
  location: 'global'
  properties: { }
}

resource Microsoft_Network_privateDnsZones_A_record1 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: zoneName_resource
  name: '@'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_A_record2 'Microsoft.Network/privateDnsZones/A@2018-09-01' = {
  parent: zoneName_resource
  name: '*'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}

resource Microsoft_Network_privateDnsZones_A_record3 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: zoneName_resource
  name: '*.scm'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}

resource zoneName_dns_to_vnet_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: zoneName_resource
  name: 'dns-to-vnet-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}
