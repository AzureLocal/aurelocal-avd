@description('Resource name of the Log Analytics workspace')
param logAnalyticsWorkspaceName string

@description('Host pool name')
param hostPoolName string

@description('Application group name')
param appGroupName string

@description('Workspace name')
param workspaceName string

var workspaceResourceId = resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' existing = {
  name: hostPoolName
}

resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' existing = {
  name: appGroupName
}

resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' existing = {
  name: workspaceName
}

resource hostPoolDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${hostPoolName}'
  scope: hostPool
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      { category: 'Checkpoint', enabled: true }
      { category: 'Error', enabled: true }
      { category: 'Management', enabled: true }
      { category: 'Connection', enabled: true }
      { category: 'HostRegistration', enabled: true }
      { category: 'AgentHealthStatus', enabled: true }
    ]
  }
}

resource appGroupDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${appGroupName}'
  scope: appGroup
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      { category: 'Checkpoint', enabled: true }
      { category: 'Error', enabled: true }
      { category: 'Management', enabled: true }
    ]
  }
}

resource workspaceDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${workspaceName}'
  scope: workspace
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      { category: 'Checkpoint', enabled: true }
      { category: 'Error', enabled: true }
      { category: 'Management', enabled: true }
      { category: 'Feed', enabled: true }
    ]
  }
}
