// modules/sessionHost.bicep
// Creates an Arc-enabled VM on Azure Local and installs the AVD Agent.

@description('VM name.')
param vmName string

@description('Azure region (must match the custom location).')
param location string

@description('Resource ID of the Arc Custom Location.')
param customLocationId string

@description('Azure Local VM size.')
param vmSize string

@description('Resource ID of the gallery image.')
param imageId string

@description('Resource ID of the virtual network.')
param vnetId string

@description('Subnet name.')
param subnetName string = 'default'

@description('AVD registration token.')
@secure()
param registrationToken string

@description('Domain FQDN.')
param domainFqdn string

@description('Domain-join user UPN.')
param domainJoinUser string

@description('Domain-join password.')
@secure()
param domainJoinPassword string

@description('OU path for the computer account.')
param ouPath string = ''

@description('Resource tags.')
param tags object = {}

// Network Interface
resource nic 'Microsoft.AzureStackHCI/networkInterfaces@2023-09-01-preview' = {
  name: '${vmName}-nic'
  location: location
  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
        }
      }
    ]
  }
}

// Session Host VM
resource vm 'Microsoft.AzureStackHCI/virtualMachineInstances@2023-09-01-preview' = {
  name: vmName
  // Arc-enabled VMs are scoped to a machine resource
  scope: machine
  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        id: imageId
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
    }
  }
}

// Machine resource required as the parent for Arc VM
resource machine 'Microsoft.HybridCompute/machines@2023-10-03-preview' = {
  name: vmName
  location: location
  tags: tags
  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }
  kind: 'HCI'
  identity: {
    type: 'SystemAssigned'
  }
}

// Domain-join extension
resource domainJoinExt 'Microsoft.HybridCompute/machines/extensions@2023-10-03-preview' = {
  parent: machine
  name: 'JsonADDomainExtension'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      domainToJoin: domainFqdn
      ouPath: ouPath
      user: domainJoinUser
      restart: 'true'
      options: '3'
    }
    protectedSettings: {
      password: domainJoinPassword
    }
  }
  dependsOn: [vm]
}

// AVD Agent (DSC extension)
resource avdAgentExt 'Microsoft.HybridCompute/machines/extensions@2023-10-03-preview' = {
  parent: machine
  name: 'AVDAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.83'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: split(vmName, '-')[0]
        registrationInfoToken: registrationToken
      }
    }
  }
  dependsOn: [domainJoinExt]
}

output vmId string = machine.id
