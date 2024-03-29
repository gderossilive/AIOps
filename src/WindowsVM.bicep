@description('Username for the Virtual Machine.')
param adminUsername string = 'gdradmin'

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string 

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param OSVersion string = '2022-Datacenter'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2ms'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string = 'simple-vm'


@description('(Existing) Virtual Network and subent where to join the VM')
param virtualNetworkName string 
param subnetName string
param Command string = ''
param CustomDnsServer string = ''


var seed = substring(uniqueString(vmName, virtualNetworkName, subnetName),0,5)
var nicName = '${vmName}-Nic-${seed}'
var publicIpName = '${vmName}-PIP-${seed}'

/*
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicIpName
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}*/


resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  name: virtualNetworkName
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
/*          publicIPAddress: {
            id: pip.id
          }*/
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vn.name, subnetName)
          }
        }
      }
    ]
    dnsSettings: {
      dnsServers: (CustomDnsServer=='') ? [] : [CustomDnsServer]
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}

resource ext 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = if (Command != '') {
  name: 'CustomScriptExtension'
  parent: vm
  location: location
  properties: {
   publisher: 'Microsoft.Compute'
   type: 'CustomScriptExtension'
   typeHandlerVersion: '1.9'
   autoUpgradeMinorVersion: true
   settings: {}
   protectedSettings: {
    commandToExecute: Command
   }
  }
}

resource shutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '1900'
    }
    timeZoneId: 'W. Europe Standard Time'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
      notificationLocale: 'en'
    }
    targetResourceId: vm.id
  }
}

output hostname string = vm.properties.osProfile.computerName
