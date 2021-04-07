param vnetName string
param location string
param dnsPrivateIp string
param subnets array
param ipAddressRange string

resource vnetHQUpdateDNS 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ipAddressRange
      ]
    }
    dhcpOptions:{
      dnsServers:[
        dnsPrivateIp
      ]
    }
    subnets: subnets
    
  }
}
