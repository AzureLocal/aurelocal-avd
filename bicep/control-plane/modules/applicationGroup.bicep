// modules/applicationGroup.bicep

@description('Application group name.')
param name string

@description('Azure region.')
param location string

@description('Resource ID of the parent host pool.')
param hostPoolId string

@description('Application group type: Desktop or RemoteApp.')
@allowed(['Desktop', 'RemoteApp'])
param applicationGroupType string = 'Desktop'

@description('Resource tags.')
param tags object = {}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: name
  location: location
  tags: tags
  properties: {
    applicationGroupType: applicationGroupType
    hostPoolArmPath: hostPoolId
  }
}

output appGroupId string = appGroup.id
