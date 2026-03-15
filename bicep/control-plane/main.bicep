// bicep/control-plane/main.bicep
// Entry-point template for the AVD control plane.
// Scope: subscription (to allow resource group creation)
//
// Deploy with:
//   az deployment sub create \
//     --location <region> \
//     --template-file main.bicep \
//     --parameters main.bicepparam

targetScope = 'subscription'

// ── Parameters ────────────────────────────────────────────────────────────────

@description('Azure region for all resources.')
param location string

@description('Name of the resource group to create for AVD resources.')
param resourceGroupName string

@description('Name of the AVD host pool.')
param hostPoolName string

@description('Type of host pool: Pooled or Personal.')
@allowed(['Pooled', 'Personal'])
param hostPoolType string = 'Pooled'

@description('Load-balancer algorithm for Pooled host pools.')
@allowed(['BreadthFirst', 'DepthFirst'])
param loadBalancerType string = 'BreadthFirst'

@description('Maximum number of concurrent sessions per session host (Pooled only).')
param maxSessionLimit int = 10

@description('Name of the AVD application group.')
param appGroupName string

@description('Name of the AVD workspace.')
param workspaceName string

@description('Name of the Azure Key Vault (must be globally unique).')
param keyVaultName string

@description('Name of the Log Analytics workspace for AVD diagnostics.')
param logAnalyticsWorkspaceName string

@description('Environment tag value.')
param environmentTag string = 'production'

@description('Owner tag value.')
param ownerTag string = 'platform-team'

// ── Variables ─────────────────────────────────────────────────────────────────

var tags = {
  environment: environmentTag
  owner: ownerTag
  deployedBy: 'bicep'
}

// ── Resource Group ────────────────────────────────────────────────────────────

module rg 'modules/resourceGroup.bicep' = {
  name: 'deploy-rg-${resourceGroupName}'
  params: {
    name: resourceGroupName
    location: location
    tags: tags
  }
}

// ── Log Analytics Workspace ───────────────────────────────────────────────────

module law 'modules/logAnalytics.bicep' = {
  name: 'deploy-law-${logAnalyticsWorkspaceName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
  }
}

// ── Key Vault ─────────────────────────────────────────────────────────────────

module kv 'modules/keyVault.bicep' = {
  name: 'deploy-kv-${keyVaultName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    name: keyVaultName
    location: location
    tags: tags
  }
}

// ── Host Pool ─────────────────────────────────────────────────────────────────

module pool 'modules/hostPool.bicep' = {
  name: 'deploy-hostpool-${hostPoolName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [rg]
  params: {
    name: hostPoolName
    location: location
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    tags: tags
  }
}

// ── Application Group ─────────────────────────────────────────────────────────

module appGroup 'modules/applicationGroup.bicep' = {
  name: 'deploy-ag-${appGroupName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [pool]
  params: {
    name: appGroupName
    location: location
    hostPoolId: pool.outputs.hostPoolId
    tags: tags
  }
}

// ── Workspace ─────────────────────────────────────────────────────────────────

module ws 'modules/workspace.bicep' = {
  name: 'deploy-ws-${workspaceName}'
  scope: resourceGroup(resourceGroupName)
  dependsOn: [appGroup]
  params: {
    name: workspaceName
    location: location
    appGroupIds: [appGroup.outputs.appGroupId]
    tags: tags
  }
}

// ── Outputs ───────────────────────────────────────────────────────────────────

output resourceGroupId string = rg.outputs.resourceGroupId
output hostPoolId string = pool.outputs.hostPoolId
output appGroupId string = appGroup.outputs.appGroupId
output workspaceId string = ws.outputs.workspaceId
output keyVaultId string = kv.outputs.keyVaultId
output logAnalyticsWorkspaceId string = law.outputs.logAnalyticsWorkspaceId
