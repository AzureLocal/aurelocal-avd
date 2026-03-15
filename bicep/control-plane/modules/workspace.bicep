// modules/workspace.bicep

@description('Workspace name.')
param name string

@description('Azure region.')
param location string

@description('List of application group resource IDs to associate with this workspace.')
param appGroupIds array

@description('Resource tags.')
param tags object = {}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2023-09-05' = {
  name: name
  location: location
  tags: tags
  properties: {
    applicationGroupReferences: appGroupIds
  }
}

output workspaceId string = workspace.id
