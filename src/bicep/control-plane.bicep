// =============================================================================
// AVD Control Plane — Subscription-Scope Wrapper
// =============================================================================
// Creates the resource group (if it doesn't exist) and deploys AVD control
// plane resources (host pool, application group, workspace) via module.
//
// targetScope = 'subscription' allows this template to:
//   1. Create or update the resource group
//   2. Deploy resources INTO that resource group via module scoping
//
// Resource file: control-plane-resources.bicep (resource-group-scope)
//
// API version: 2024-04-03 (latest GA — stable, well-documented)
// =============================================================================

targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters — Resource Group
// ---------------------------------------------------------------------------

@description('Name of the resource group for AVD control plane resources. Created if it does not exist.')
param resourceGroupName string

@description('Azure region for the resource group and all control plane resources')
param location string

// ---------------------------------------------------------------------------
// Parameters — Host Pool
// ---------------------------------------------------------------------------

@description('Name of the AVD host pool')
@minLength(3)
@maxLength(64)
param hostPoolName string

@description('Host pool type — Personal (1:1 dedicated) or Pooled (shared multi-user)')
@allowed([
  'Personal'
  'Pooled'
])
param hostPoolType string = 'Pooled'

@description('Load balancing algorithm — BreadthFirst (spread) or DepthFirst (fill). Ignored for Personal (forced to Persistent).')
@allowed([
  'BreadthFirst'
  'DepthFirst'
])
param loadBalancerType string = 'BreadthFirst'

@description('Maximum concurrent sessions per session host (Pooled only)')
@minValue(1)
@maxValue(999999)
param maxSessionLimit int = 16

@description('Preferred application group type — Desktop or RailApplications (RemoteApp)')
@allowed([
  'Desktop'
  'RailApplications'
  'None'
])
param preferredAppGroupType string = 'Desktop'

@description('Personal desktop assignment type — Automatic or Direct (Personal only)')
@allowed([
  'Automatic'
  'Direct'
])
param personalDesktopAssignmentType string = 'Automatic'

@description('Enable Start VM on Connect (requires Desktop Virtualization Power On Contributor RBAC)')
param startVMOnConnect bool = false

@description('Mark as validation environment (receives service updates before production)')
param validationEnvironment bool = false

@description('Custom RDP properties string (semicolon-delimited, e.g., "audiocapturemode:i:1;redirectclipboard:i:1")')
param customRdpProperty string = ''

@description('Friendly display name for the host pool in Azure portal')
param hostPoolFriendlyName string = ''

@description('Description of the host pool')
param hostPoolDescription string = ''

// ---------------------------------------------------------------------------
// Parameters — Application Group
// ---------------------------------------------------------------------------

@description('Name of the application group')
@minLength(3)
@maxLength(64)
param appGroupName string

@description('Application group type — Desktop (full desktop) or RemoteApp (individual apps)')
@allowed([
  'Desktop'
  'RemoteApp'
])
param appGroupType string = 'Desktop'

@description('Friendly display name for the application group')
param appGroupFriendlyName string = ''

// ---------------------------------------------------------------------------
// Parameters — Workspace
// ---------------------------------------------------------------------------

@description('Name of the AVD workspace')
@minLength(3)
@maxLength(64)
param workspaceName string

@description('Friendly display name for the workspace')
param workspaceFriendlyName string = ''

// ---------------------------------------------------------------------------
// Parameters — Tags
// ---------------------------------------------------------------------------

@description('Resource tags applied to the resource group and all control plane resources')
param tags object = {}

@description('Enable Microsoft Entra ID single sign-on (appends enablerdsaadauth:i:1 to host pool RDP properties)')
param enableEntraIdAuth bool = false

// ---------------------------------------------------------------------------
// Resource Group — created at subscription scope
// ---------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Module — deploy control plane resources into the resource group
// ---------------------------------------------------------------------------

module controlPlane './control-plane-resources.bicep' = {
  scope: rg
  name: 'avd-control-plane-${uniqueString(resourceGroupName)}'
  params: {
    hostPoolName: hostPoolName
    location: location
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    maxSessionLimit: maxSessionLimit
    preferredAppGroupType: preferredAppGroupType
    personalDesktopAssignmentType: personalDesktopAssignmentType
    startVMOnConnect: startVMOnConnect
    validationEnvironment: validationEnvironment
    customRdpProperty: customRdpProperty
    hostPoolFriendlyName: hostPoolFriendlyName
    hostPoolDescription: hostPoolDescription
    appGroupName: appGroupName
    appGroupType: appGroupType
    appGroupFriendlyName: appGroupFriendlyName
    workspaceName: workspaceName
    workspaceFriendlyName: workspaceFriendlyName
    tags: tags
    enableEntraIdAuth: enableEntraIdAuth
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output resourceGroupName string = rg.name
output hostPoolId string = controlPlane.outputs.hostPoolId
output hostPoolName string = controlPlane.outputs.hostPoolName
output appGroupId string = controlPlane.outputs.appGroupId
output appGroupName string = controlPlane.outputs.appGroupName
output workspaceId string = controlPlane.outputs.workspaceId
output workspaceName string = controlPlane.outputs.workspaceName
