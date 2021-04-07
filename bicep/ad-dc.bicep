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
param virtualMachineName string = 'vm-hq-dc'

@description('The name of the virtualNetwork.')
param virtualNetworkName string

@description('The name of the subnet.')
param subnetName string

@description('Private IP address.')
param privateIPAddress string = '10.100.0.4'

@description('Use Azure DNS on NIC config.')
param useAzureDNS bool = true

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
    dnsSettings:{
      dnsServers:[
        '168.63.129.16'
      ]
    }
  }
}

resource virtualMachineName_resource 'Microsoft.Compute/virtualMachines@2020-12-01' = {
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
          diskSizeGB: 20
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

resource virtualMachineName_CreateADForest 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${virtualMachineName_resource.name}/CreateADForest'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.19'
    autoUpgradeMinorVersion: true
    settings: {
      ModulesUrl: uri(artifactsLocation, 'CreateADPDC.zip${artifactsLocationSasToken}')
      ConfigurationFunction: 'CreateADPDC.ps1\\CreateADPDC'
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
}

output dnsIpAddress string = privateIPAddress
output domainName string = domainName
