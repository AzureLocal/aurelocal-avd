@description('Location for extension resources')
param location string

@description('Session host machine names')
param machineNames array

@description('FSLogix profile share UNC path')
param profileSharePath string

@description('FSLogix profile max size in MB')
param sizeInMBs int = 30720

var fslogixCommand = 'cmd /c echo FSLogix configuration placeholder'

resource fslogixExtensions 'Microsoft.HybridCompute/machines/extensions@2023-06-20-preview' = [for vmName in machineNames: {
  name: '${vmName}/FSLogixConfig'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      profileSharePath: profileSharePath
      sizeInMBs: sizeInMBs
    }
    protectedSettings: {
      commandToExecute: fslogixCommand
    }
  }
}]
