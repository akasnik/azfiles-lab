@description('The name of the administrator account of the new VM and domain join credentials')
param adminUsername string

@description('The password for the administrator account of the new VM and domain join credentials')
@secure()
param adminPassword string 

@description('The FQDN of the Active Directory Domain to join')
param domainName string

@description('Size of the VM')
param vmSize string = 'Standard_B2ms'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual machine name.')
param virtualMachineName string = 'vm-hq-client-1'

@description('The name of the virtualNetwork.')
param virtualNetworkName string

@description('The name of the subnet.')
param subnetName string

@description('Private IP address.')
param privateIPAddress string = '10.100.10.5'

@description('The location of resources, such as DSC modules, that the template depends on')
param artifactsLocation string = 'https://github.com/akasnik/azfiles-lab/raw/main/dsc/'

@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
@secure()
param artifactsLocationSasToken string = ''

var networkInterfaceName = '${virtualMachineName}-nic'

resource nic 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: privateIPAddress
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h1-pro'
        version: 'latest'
      }
      osDisk: {
        name: '${virtualMachineName}_OSDisk'
        caching: 'ReadOnly'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource vm_configClient 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/ConfigClient'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'ConfigClient.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'ConfigClient.ps1\\ConfigClient'
      Properties: {        
        DomainName: domainName
        AdminCreds: {
          UserName: adminUsername
          Password: 'PrivateSettingsRef:AdminPassword'
        }
      }
    }
    protectedSettings: {
      Items: {
        AdminPassword: adminPassword
      }
    }
  }
  dependsOn: [
    vm_domainJoin
  ]
}

resource vm_domainJoin 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vm.name}/joindomain'
  location: location
  dependsOn: [
    vm
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainName
      User: '${adminUsername}@${domainName}'
      Restart: true
      Options: 3
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
}

/*
resource vm_configshare 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${virtualMachineName_resource.name}/config-fileshare'
  location: location
  dependsOn: [
    vm_domainJoin
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      timestamp: 123456789
    }
    protectedSettings: {
      commandToExecute: 'powershell.exe ${configureFileShareScript}'
    }
  }
}
*/


output dnsIpAddress string = privateIPAddress
