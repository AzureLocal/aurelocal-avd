// modules/logAnalytics.bicep

@description('Log Analytics workspace name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

output logAnalyticsWorkspaceId string = law.id
output logAnalyticsWorkspaceKey string = law.listKeys().primarySharedKey
