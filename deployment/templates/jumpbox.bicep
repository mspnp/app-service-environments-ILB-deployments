@description('The location in which the resources should be deployed.')
param location string = resourceGroup().location

@description('The vnet name where the jumpbox will be connected.')
param vnetName string

@description('The ip address prefix that jumpbox subnet will use.')
param subnetAddressPrefix string

@description('The admin user name.')
param adminUsername string

@description('The admin password.')
@secure()
param adminPassword string

var computerName = 'votingjb'
var jumpboxName_var = 'jumpbox-${computerName}${uniqueString(resourceGroup().id)}'
var jumpboxSubnetName = 'jumpbox-subnet-${uniqueString(resourceGroup().id)}'
var jumpboxSubnetId = vnetName_jumpboxSubnetName.id
var jumpboxPublicIpName_var = 'jumpbox-pip-${uniqueString(resourceGroup().id)}'
var jumpboxNSGName_var = '${vnetName}-JUMPBOX-NSG'
var jumpboxNicName_var = 'jumpbox-nic-${uniqueString(resourceGroup().id)}'

resource jumpboxPublicIpName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: jumpboxPublicIpName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource jumpboxNSGName 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: jumpboxNSGName_var
  location: location
  tags: {
    displayName: jumpboxNSGName_var
  }
  properties: {
    securityRules: [
      {
        name: 'JUMPBOX-inbound-allow_RDP'
        properties: {
          description: 'Allow Inbound-JumpBoxRDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: subnetAddressPrefix
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vnetName_jumpboxSubnetName 'Microsoft.Network/virtualNetworks/subnets@2022-07-01' = {
  name: '${vnetName}/${jumpboxSubnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: jumpboxNSGName.id
    }
  }
}

resource jumpboxNicName 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: jumpboxNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: jumpboxSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/publicIpAddresses', jumpboxPublicIpName_var)
          }
        }
      }
    ]
  }
}

resource jumpboxName 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: jumpboxName_var
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS2_v2'
    }
    storageProfile: {
      osDisk: {
        createOption: 'fromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter-smalldisk'
        version: 'latest'
      }
      dataDisks: [
        {
          diskSizeGB: 512
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpboxNicName.id
        }
      ]
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

output jumpboxName string = jumpboxName_var
output jumpboxSubnetName string = jumpboxSubnetName
output jumpboxPublicIpAddress string = jumpboxPublicIpName.properties.ipAddress
