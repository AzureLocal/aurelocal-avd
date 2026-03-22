// =============================================================================
// AVD Monitoring & Diagnostics — Bicep
// =============================================================================
// Deploys diagnostic settings on AVD resources (host pool, workspace,
// application group) and optional metric alert rules.
// =============================================================================

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name of the host pool (used for diagnostic setting names)')
param hostPoolName string

@description('Resource ID of the AVD host pool')
param hostPoolId string

@description('Resource ID of the AVD workspace')
param workspaceId string

@description('Resource ID of the AVD application group')
param appGroupId string

@description('Resource ID of the Log Analytics workspace')
param logAnalyticsWorkspaceId string

@description('Enable diagnostic settings')
param monitoringEnabled bool = true

@description('Log categories to enable on the host pool')
param diagnosticsLogCategories array = [
  'Checkpoint'
  'Error'
  'Management'
  'Connection'
  'HostRegistration'
  'AgentHealthStatus'
]

@description('Enable metric alert rules')
param alertRulesEnabled bool = false

@description('Resource ID of the action group for alert notifications (empty = no action)')
param alertActionGroupId string = ''

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Diagnostic Settings — Host Pool
// ---------------------------------------------------------------------------

resource hostPoolDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (monitoringEnabled) {
  name: '${hostPoolName}-diag'
  scope: hostPoolResource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [for cat in diagnosticsLogCategories: {
      category: cat
      enabled: true
    }]
  }
}

// Reference existing resources by ID
resource hostPoolResource 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' existing = {
  name: last(split(hostPoolId, '/'))
}

resource workspaceResource 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' existing = {
  name: last(split(workspaceId, '/'))
}

resource appGroupResource 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' existing = {
  name: last(split(appGroupId, '/'))
}

// ---------------------------------------------------------------------------
// Diagnostic Settings — Workspace
// ---------------------------------------------------------------------------

resource workspaceDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (monitoringEnabled) {
  name: '${last(split(workspaceId, '/'))}-diag'
  scope: workspaceResource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Feed'
        enabled: true
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Diagnostic Settings — Application Group
// ---------------------------------------------------------------------------

resource appGroupDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (monitoringEnabled) {
  name: '${last(split(appGroupId, '/'))}-diag'
  scope: appGroupResource
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Checkpoint'
        enabled: true
      }
      {
        category: 'Error'
        enabled: true
      }
      {
        category: 'Management'
        enabled: true
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Alert Rule — No Available Session Hosts
// ---------------------------------------------------------------------------

resource noAvailableHostsAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = if (alertRulesEnabled) {
  name: '${hostPoolName}-no-available-hosts'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when no session hosts are available.'
    severity: 1
    enabled: true
    scopes: [
      hostPoolId
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'NoAvailableHosts'
          criterionType: 'StaticThresholdCriterion'
          metricNamespace: 'Microsoft.DesktopVirtualization/hostpools'
          metricName: 'SessionHostHealthCheckSucceededCount'
          operator: 'LessThan'
          threshold: 1
          timeAggregation: 'Average'
        }
      ]
    }
    actions: !empty(alertActionGroupId) ? [
      {
        actionGroupId: alertActionGroupId
      }
    ] : []
  }
}
