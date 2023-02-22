@description('Location for Azure hub and Azure Files resources.')
param locationAZHub string = resourceGroup().location
@description('Name of Azure Hub VNet.')
param vnetAZHubName string = 'vnet-azhub'

@description('Location for Azure hub and Azure Files resources.')
param locationHQ string = resourceGroup().location
@description('Name of HQ Hub VNet.')
param vnetHQName string = 'vnet-hq'

@description('Location for Azure hub and Azure Files resources.')
param locationBranch string = resourceGroup().location
@description('Name of Branch VNet.')
param vnetBranchName string = 'vnet-branch-1'

@description('The name of the administrator account of the new VM and domain')
param adminUsername string = 'azadmin'

@description('The password for the administrator account of the new VM and domain')
@secure()
param adminPassword string 

@description('The FQDN of the Active Directory Domain to be created')
param domainName string = 'contoso.com'

@description('Size of the VM for the servers')
param vmSize string = 'Standard_D2ds_v4'

@description('Size of the VM for the clients')
param vmSizeClient string = 'Standard_B2ms'

@description('The location of resources, such as templates and DSC modules, that the template depends on')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
@secure()
param artifactsLocationSasToken string = ''

var dnsPrivateIp = '10.100.0.4'

// Deploy AZ Hub VNet
resource vnetAzHub 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetAZHubName
  location: locationAZHub
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    dhcpOptions:{
      dnsServers:[
        dnsPrivateIp
      ]
    }
    subnets: [
      {
        name: 'SharedServices'
        properties: {
          addressPrefix: '192.168.0.0/24'
        }
      }
      {
        name: 'Client'
        properties: {
          addressPrefix: '192.168.10.0/24'
        }
      }      
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '192.168.254.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '192.168.255.0/24'
        }
      }
    ]
  }
}

// Deploy HQ VNet
resource vnetHQ 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetHQName
  location: locationHQ
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    dhcpOptions:{
      dnsServers:[
        dnsPrivateIp
      ]
    }
    subnets: [
      {
        name: 'SharedServices'
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      }
      {
        name: 'Client'
        properties: {
          addressPrefix: '10.100.10.0/24'
        }
      }      
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.100.254.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.100.255.0/24'
        }
      }
    ]
  }
}

// Deploy Branch 1 VNet
resource vnetBranch1 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetBranchName
  location: locationBranch
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.200.0.0/16'
      ]
    }
    dhcpOptions:{
      dnsServers:[
        dnsPrivateIp
      ]
    }
    subnets: [
      {
        name: 'SharedServices'
        properties: {
          addressPrefix: '10.200.0.0/24'
        }
      }
      {
        name: 'Client'
        properties: {
          addressPrefix: '10.200.10.0/24'
        }
      }      
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.200.254.0/24'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.200.255.0/24'
        }
      }
    ]
  }
}

// Deploy vnet peerings
resource peeringHQBranch 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetHQ.name}/peering-hq-branch'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetBranch1.id
    }
  }
}

resource peeringBranchHQ 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetBranch1.name}/peering-branch-hq'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHQ.id
    }
  }
}

resource peeringHQAzHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetHQ.name}/peering-hq-azhub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetAzHub.id
    }
  }
}

resource peeringAzHubhHQ 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${vnetAzHub.name}/peering-azhub-hq'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHQ.id
    }
  }
}

// Deploy Bastion
@description('Name of Bastion for accessing HQ')
param bastionHQName string = 'bastion-hq'

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: '${bastionHQName}-pip'
  location: locationHQ
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: 'bastion-hq'
  location: locationHQ
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig'
        properties:{
          subnet:{
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetHQ.name, 'AzureBastionSubnet')
          }
          publicIPAddress: {
            id: publicIPAddressName.id
          }
        }
      }
    ]
  }
}

// Deploy HQ DC VM
module hqdcvm './ad-dc.bicep' = {
  name: 'hqdcvm'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    artifactsLocation: artifactsLocation
    artifactsLocationSasToken: artifactsLocationSasToken
    virtualNetworkName: vnetHQ.name
    subnetName: 'SharedServices'
    domainName: domainName
    location: locationHQ
    privateIPAddress: dnsPrivateIp
    virtualMachineName: 'vm-hq-dc'
  }
}

module hqfsvm './fs.bicep' = {
  name: 'hqfsvm'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    artifactsLocation: artifactsLocation
    artifactsLocationSasToken: artifactsLocationSasToken
    virtualNetworkName: vnetHQ.name
    subnetName: 'SharedServices'
    domainName: domainName
    location: locationHQ
    privateIPAddress: '10.100.0.5'
    virtualMachineName:'vm-hq-fs-1'
  }
  dependsOn: [
    hqdcvm
  ]
}

module brfsvm './fs.bicep' = {
  name: 'brfsvm'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    artifactsLocation: artifactsLocation
    artifactsLocationSasToken: artifactsLocationSasToken
    virtualNetworkName: vnetBranch1.name
    subnetName: 'SharedServices'
    domainName: domainName
    location: locationBranch
    privateIPAddress: '10.200.0.5'
    virtualMachineName:'vm-branch1-fs-1'
    deployShare: false
  }
  dependsOn: [
    hqdcvm
  ]
}

module hqclivm './client.bicep' = {
  name: 'hqclivm'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSizeClient
    artifactsLocation: artifactsLocation
    artifactsLocationSasToken: artifactsLocationSasToken
    virtualNetworkName: vnetHQ.name
    subnetName: 'Client'
    domainName: domainName
    location: locationHQ
    privateIPAddress: '10.100.10.4'
    virtualMachineName:'vm-hq-client-1'
  }
  dependsOn: [
    hqdcvm
  ]
}

// Add Application server in Azure hub
module azappvm './appserver.bicep' = {
  name: 'azappvm'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    artifactsLocation: artifactsLocation
    artifactsLocationSasToken: artifactsLocationSasToken
    virtualNetworkName: vnetAzHub.name
    subnetName: 'SharedServices'
    domainName: domainName
    location: locationAZHub
    privateIPAddress: '192.168.0.5'
    virtualMachineName:'vm-az-app-1'
  }
  dependsOn: [
    hqdcvm
  ]
}
