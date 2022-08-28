@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the gateway will be connected.')
param vnetName string

@description('The ip address prefix that gateway will use.')
param appgwSubnetAddressPrefix string

@description('List of applications to configure. Each element format is: { name, hostName, backendAddresses, certificate: { data, password }, probePath }')
param appgwApplications array

@description('Comma separated application gateway zones.')
param appgwZones string = ''

var appgwName_var = 'appgw'
//var appgwId = resourceId('',appgwName)
var appgwSubnetName = 'appgw-subnet-${appgwName_var}'
var appgwSubnetId = vnetName_appgwSubnetName.id
var appgwNSGName_var = '${vnetName}-APPGW-NSG'
var appgwPublicIpAddressName_var = 'AppGatewayIp'
var appGwPublicIpAddressId = appgwPublicIpAddressName.id
var appgwIpConfigName = '${appgwName_var}-ipconfig'
var appgwFrontendName = '${appgwName_var}-frontend'
var appgwBackendName = '${appgwName_var}-backend-'
var appgwHttpSettingsName = '${appgwName_var}-httpsettings-'
var appgwHealthProbeName = '${appgwName_var}-healthprobe-'
var appgwListenerName = '${appgwName_var}-listener-'
var appgwSslCertificateName = '${appgwName_var}-ssl-'
var appgwRouteRulesName = '${appgwName_var}-routerules-'
var appgwAutoScaleMinCapacity = 0
var appgwAutoScaleMaxCapacity = 10
var appgwZonesArray = (empty(appgwZones) ? json('null') : split(appgwZones, ','))

resource appgwPublicIpAddressName 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: appgwPublicIpAddressName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource appgwNSGName 'Microsoft.Network/networkSecurityGroups@2022-01-01' = {
  name: appgwNSGName_var
  location: location
  tags: {
    displayName: appgwNSGName_var
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
          destinationAddressPrefix: appgwSubnetAddressPrefix
          access: 'Allow'
          priority: 202
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName_appgwSubnetName 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${vnetName}/${appgwSubnetName}'
  //location: location
  properties: {
    addressPrefix: appgwSubnetAddressPrefix
    networkSecurityGroup: { id: appgwNSGName.id }
  }
}

resource appgwName 'Microsoft.Network/applicationGateways@2022-01-01' = {
  name: appgwName_var
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
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/probes/${appgwHealthProbeName}${item.name}'
        }
      }
    }]
    httpListeners: [for item in appgwApplications: {
      name: '${appgwListenerName}${item.name}'
      properties: {
        frontendIPConfiguration: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/frontendIPConfigurations/${appgwFrontendName}'
        }
        frontendPort: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/frontendPorts/port_443'
        }
        protocol: 'Https'
        sslCertificate: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/sslCertificates/${appgwSslCertificateName}${item.name}'
        }
        hostName: item.hostName
        requireServerNameIndication: true
      }
    }]
    requestRoutingRules: [for item in appgwApplications: {
      name: '${appgwRouteRulesName}${item.name}'
      properties: {
        ruleType: 'Basic'
        httpListener: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/httpListeners/${appgwListenerName}${item.name}'
        }
        backendAddressPool: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/backendAddressPools/${appgwBackendName}${item.name}'
        }
        backendHttpSettings: {
          id: '${resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appgwName_var)}/backendHttpSettingsCollection/${appgwHttpSettingsName}${item.name}'
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

output appGwPublicIpAddress string = appgwPublicIpAddressName.properties.ipAddress
