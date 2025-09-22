@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the gateway will be connected.')
param vnetName string

@description('The ip address prefix that gateway will use.')
param subnetAddressWithPrefix string = '10.0.1.0/24'

@description('List of applications to configure. Each element format is: { name, hostName, backendAddresses, certificate: { data, password }, probePath }')
param appgwApplications array

@description('Comma separated application gateway zones.')
param appgwZones string = ''

var appGatewayName = '${vnetName}-appgw'
var subnetNameWithoutSegment = '${appGatewayName}-subnet'
var subnetName = '${vnetName}/${subnetNameWithoutSegment}'
var appgwId = resourceId('Microsoft.Network/applicationGateways', appGatewayName)
var appgwSubnetId = appGatewaySubnet.id
var appgwNSGName = '${vnetName}-appgw-NSG'
var appgwPublicIpAddressName = '${vnetName}-appgw-Ip'
var appGwPublicIpAddressId = resourceId('Microsoft.Network/publicIPAddresses',appgwPublicIpAddressName)
var appgwIpConfigName = '${appGatewayName}-ipconfig'
var appgwFrontendName = '${appGatewayName}-frontend'
var appgwBackendName = '${appGatewayName}-backend-'
var appgwHttpSettingsName = '${appGatewayName}-httpsettings-'
var appgwHealthProbeName = '${appGatewayName}-healthprobe-'
var appgwListenerName = '${appGatewayName}-listener-'
var appgwSslCertificateName = '${appGatewayName}-ssl-'
var appgwRouteRulesName = '${appGatewayName}-routerules-'
var appgwAutoScaleMinCapacity = 0
var appgwAutoScaleMaxCapacity = 10
var appgwZonesArray = (empty(appgwZones) ? null : split(appgwZones, ','))

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: appgwPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: appgwNSGName
  location: location
  tags: {
    displayName: appgwNSGName
  }
  properties: {
    securityRules: [
      {
        name: 'APPGW-inbound-allow_infrastructure'
        properties: {
          description: 'Used to manage AppGW from Azure'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'APPGW-Inbound-load-balancer'
        properties: {
          description: 'Allow communication from Load Balancer'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 201
          direction: 'Inbound'
        }
      }
      {
        name: 'APPGW-inbound-allow_web'
        properties: {
          description: 'Allow web traffic from internet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: subnetAddressWithPrefix
          access: 'Allow'
          priority: 202
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource appGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: subnetName
  properties: {
    addressPrefix: subnetAddressWithPrefix
    defaultOutboundAccess: false
    networkSecurityGroup: { id: networkSecurityGroup.id, location: location }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: appGatewayName
  location: location
  zones: appgwZonesArray
  tags: {
  }
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
    }
    gatewayIPConfigurations: [
      {
        name: appgwIpConfigName
        properties: {
          subnet: {
            id: appgwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appgwFrontendName
        properties: {
          publicIPAddress: {
            id: appGwPublicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_443'
        properties: {
          port: 443
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: appgwAutoScaleMinCapacity
      maxCapacity: appgwAutoScaleMaxCapacity
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Detection'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
    }
    enableHttp2: false
    backendAddressPools: [for item in appgwApplications: {
      name: '${appgwBackendName}${item.name}'
      properties: {   
        backendAddresses: item.backendAddresses
      }
    }]
    backendHttpSettingsCollection: [for item in appgwApplications: {
      name: '${appgwHttpSettingsName}${item.name}'
      properties: {
        port: 443
        protocol: 'Https'
        cookieBasedAffinity: 'Disabled'
        pickHostNameFromBackendAddress: true
        requestTimeout: 20
        probe: {
          id: '${appgwId}/probes/${appgwHealthProbeName}${item.name}'
        }
      }
    }]
    httpListeners: [for item in appgwApplications: {
      name: '${appgwListenerName}${item.name}'
      properties: {
        frontendIPConfiguration: {
          id: '${appgwId}/frontendIPConfigurations/${appgwFrontendName}'
        }
        frontendPort: {
          id: '${appgwId}/frontendPorts/port_443'
        }
        protocol: 'Https'
        sslCertificate: {
          id: '${appgwId}/sslCertificates/${appgwSslCertificateName}${item.name}'
        }
        hostName: item.hostName
        requireServerNameIndication: true
      }
    }]
    requestRoutingRules: [for item in appgwApplications: {
      name: '${appgwRouteRulesName}${item.name}'
      properties: {
        priority: item.routingPriority
        ruleType: 'Basic'
        httpListener: {
          id: '${appgwId}/httpListeners/${appgwListenerName}${item.name}'
        }
        backendAddressPool: {
          id: '${appgwId}/backendAddressPools/${appgwBackendName}${item.name}'
        }
        backendHttpSettings: {
          id: '${appgwId}/backendHttpSettingsCollection/${appgwHttpSettingsName}${item.name}'
        }
      }
    }]
    probes: [for item in appgwApplications: {
      name: '${appgwHealthProbeName}${item.name}'
      properties: {
        protocol: 'Https'
        path: item.probePath
        interval: 30
        timeout: 30
        unhealthyThreshold: 3
        pickHostNameFromBackendHttpSettings: true
        minServers: 0
        match: {
          statusCodes: [
            '200-399'
          ]
        }
      }
    }]
    sslCertificates: [for item in appgwApplications: {
      name: '${appgwSslCertificateName}${item.name}'
      properties: {
        data: item.certificate.data
        password: item.certificate.password
      }
    }]
  }
}

output appGwPublicIpAddress string = publicIPAddress.properties.ipAddress
