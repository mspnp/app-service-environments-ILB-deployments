@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the ASE will be connected.')
param vnetName string

@description('The vnet route name for ASE subnet.')
param vnetRouteName string

@description('The ip address prefix that ASE will use.')
param aseSubnetAddressPrefix string

@description('Required. Dedicated host count of ASEv3.')
param dedicatedHostCount int = 0

@description('Required. Zone redundant of ASEv3.')
param zoneRedundant bool = false


var aseName_var = 'ASE-${uniqueString(resourceGroup().id)}'
var aseNSGName_var = 'ASE-nsg-${uniqueString(resourceGroup().id)}'
var aseId = aseName.id
var aseSubnetName = 'ase-subnet-${aseName_var}-1'
var aseSubnetId = vnetName_aseSubnetName.id
var aseLoadBalancingMode = 'Web, Publishing'


resource aseNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: aseNSGName_var
  location: location
  tags: {
    displayName: aseNSGName_var
  }
  properties: {
    securityRules: [
      {
        name: 'ASE-inbound-allow_web_traffic_from_app_gateway'
        properties: {
          description: 'Allow web traffic from app gateway'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'ASE-inbound-deny-all'
        properties: {
          description: 'Deny all other traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 250
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName_aseSubnetName 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${vnetName}/${aseSubnetName}'  
  properties: {
    addressPrefix: aseSubnetAddressPrefix
    networkSecurityGroup: {
      id: aseNSGName.id
    }
    delegations: [
      {
        name: 'Microsoft.Web.hostingEnvironments'
        properties: {
          serviceName: 'Microsoft.Web/hostingEnvironments'
        }
      }
    ]
    routeTable: {
      id: resourceId('Microsoft.Network/routeTables', vnetRouteName)
    }    
  }
}

resource aseName 'Microsoft.Web/hostingEnvironments@2022-03-01' = {
  name: aseName_var
  location: location
  kind: 'ASEV3'
  properties: {
    dedicatedHostCount: dedicatedHostCount
    zoneRedundant: zoneRedundant
    internalLoadBalancingMode: aseLoadBalancingMode
    virtualNetwork: {
      id: aseSubnetId 
    }
  }
}

output dnsSuffix string = reference(aseId).dnsSuffix
output aseId string = aseId 
output aseSubnetName string = aseSubnetName
output aseName string = aseName_var
