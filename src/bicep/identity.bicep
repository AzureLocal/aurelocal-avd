@description('Application group name for Desktop Virtualization User role assignment scope')
param appGroupName string

@description('User group object ID for Desktop Virtualization User role')
param desktopVirtualizationUserGroupId string = ''

@description('Resource group scope principal for Start VM on Connect role')
param startVmOnConnectPrincipalId string = ''

var desktopVirtualizationUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1d336d6b-1444-4a47-9fbb-26e0a0e4f6bb')
var desktopVirtualizationPowerOnRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '40c5ff49-9181-41f8-ae61-143b0e78555e')

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' existing = {
  name: appGroupName
}

resource desktopVirtualizationUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(desktopVirtualizationUserGroupId)) {
  name: guid(appGroup.id, desktopVirtualizationUserGroupId, desktopVirtualizationUserRoleId)
  scope: appGroup
  properties: {
    roleDefinitionId: desktopVirtualizationUserRoleId
    principalId: desktopVirtualizationUserGroupId
    principalType: 'Group'
  }
}

resource powerOnContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(startVmOnConnectPrincipalId)) {
  name: guid(resourceGroup().id, startVmOnConnectPrincipalId, desktopVirtualizationPowerOnRoleId)
  properties: {
    roleDefinitionId: desktopVirtualizationPowerOnRoleId
    principalId: startVmOnConnectPrincipalId
    principalType: 'ServicePrincipal'
  }
}
