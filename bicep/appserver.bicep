@description('The name of the administrator account of the new VM and domain')
param adminUsername string

@description('The password for the administrator account of the new VM and domain')
@secure()
param adminPassword string 

@description('The FQDN of the Active Directory Domain to be created')
param domainName string

@description('Size of the VM for the controller')
param vmSize string = 'Standard_D2ds_v4'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Virtual machine name.')
param virtualMachineName string = 'vm-az-app-1'

@description('The name of the virtualNetwork.')
param virtualNetworkName string

@description('The name of the subnet.')
param subnetName string

@description('Private IP address.')
param privateIPAddress string = '192.168.0.5'

@description('The location of resources, such as DSC modules, that the template depends on')
param artifactsLocation string = 'https://github.com/akasnik/azfiles-lab/raw/main/dsc/'

@description('Auto-generated token to access _artifactsLocation. Leave it blank unless you need to provide your own value.')
@secure()
param artifactsLocationSasToken string = ''

param deployShare bool = true

var networkInterfaceName = '${virtualMachineName}-nic'

var configureFileShareScript = ''

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
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2016-Datacenter'
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
      dataDisks: [
        {
          name: '${virtualMachineName}_DataDisk'
          caching: 'ReadWrite'
          createOption: 'Empty'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          lun: 0
        }
      ]
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

resource vm_configAppServer 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/ConfigAppServer'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'ConfigAppServer.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'ConfigAppServer.ps1\\ConfigAppServer'
      Properties: {
        ShareDriveLetter: 'F'
        ShareFolder: 'F:\\Share1'
        ShareName: 'Share1'
        //GitRepo: 'https://github.com/akasnik/azure-quickstart-templates.git'
        DeployShare: deployShare
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
