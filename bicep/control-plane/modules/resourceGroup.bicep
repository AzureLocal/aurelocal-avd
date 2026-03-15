// modules/resourceGroup.bicep
targetScope = 'subscription'

@description('Resource group name.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
  tags: tags
}

output resourceGroupId string = rg.id
