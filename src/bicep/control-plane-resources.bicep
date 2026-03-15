// =============================================================================
// AVD Control Plane — Host Pool, Application Group, Workspace
// =============================================================================
// Deploys the AVD control plane resources into the host pool resource group.
// These are Azure-hosted management resources that broker connections to
// session hosts running on Azure Local.
//
// Dependency chain:
//   Host Pool → Application Group (references host pool) → Workspace (references app group)
//
// This template is SEPARATE from session-hosts/main.bicep because:
//   - Different target resource group (host pool RG vs session host RG)
//   - Different lifecycle (deploy once, update in-place vs deploy per batch)
//   - Control plane resources live in the AVD subscription management plane
//
// API version: 2024-04-03 (latest GA — stable, well-documented)
// =============================================================================

// ---------------------------------------------------------------------------
// Parameters — Host Pool
// ---------------------------------------------------------------------------

@description('Name of the AVD host pool')
@minLength(3)
@maxLength(64)
param hostPoolName string

@description('Azure region for AVD control plane resources')
param location string

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

@description('Resource tags applied to all control plane resources')
param tags object = {}

@description('Enable Microsoft Entra ID single sign-on. Appends enablerdsaadauth:i:1 to the host pool RDP properties automatically.')
param enableEntraIdAuth bool = false

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// For Personal host pools, loadBalancerType MUST be 'Persistent' — enforce it
var effectiveLoadBalancerType = hostPoolType == 'Personal' ? 'Persistent' : loadBalancerType

// When Entra ID auth is enabled, append the SSO RDP property so the RD client
// requests an Entra token during connection. This is non-destructive — any
// existing custom RDP properties are preserved with a semicolon separator.
var entraRdpProperty = 'enablerdsaadauth:i:1'
var effectiveCustomRdpProperty = enableEntraIdAuth
  ? (empty(customRdpProperty) ? entraRdpProperty : '${customRdpProperty};${entraRdpProperty}')
  : customRdpProperty

// ---------------------------------------------------------------------------
// Resources
// ---------------------------------------------------------------------------

// Resource 1: Host Pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: location
  tags: tags
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: effectiveLoadBalancerType
    preferredAppGroupType: preferredAppGroupType
    maxSessionLimit: hostPoolType == 'Pooled' ? maxSessionLimit : 1
    personalDesktopAssignmentType: hostPoolType == 'Personal' ? personalDesktopAssignmentType : null
    startVMOnConnect: startVMOnConnect
    validationEnvironment: validationEnvironment
    customRdpProperty: effectiveCustomRdpProperty
    friendlyName: !empty(hostPoolFriendlyName) ? hostPoolFriendlyName : hostPoolName
    description: hostPoolDescription
    // Registration token is NOT generated here — the deploy script handles it
    // via New-AzWvdRegistrationInfo after this template deploys. This avoids
    // the unreliable pattern of extracting tokens from Bicep outputs.
  }
}

// Resource 2: Application Group
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2024-04-03' = {
  name: appGroupName
  location: location
  tags: tags
  properties: {
    applicationGroupType: appGroupType
    hostPoolArmPath: hostPool.id
    friendlyName: !empty(appGroupFriendlyName) ? appGroupFriendlyName : appGroupName
  }
}

// Resource 3: Workspace
resource workspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: workspaceName
  location: location
  tags: tags
  properties: {
    friendlyName: !empty(workspaceFriendlyName) ? workspaceFriendlyName : workspaceName
    applicationGroupReferences: [
      appGroup.id
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output hostPoolId string = hostPool.id
output hostPoolName string = hostPool.name
output appGroupId string = appGroup.id
output appGroupName string = appGroup.name
output workspaceId string = workspace.id
output workspaceName string = workspace.name
