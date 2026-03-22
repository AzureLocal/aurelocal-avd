// =============================================================================
// AVD Session Hosts on Azure Local — Subscription-Scope Wrapper
// =============================================================================
// Creates the resource group (if it doesn't exist) and deploys session host
// VMs onto an Azure Local cluster via module.
//
// targetScope = 'subscription' allows this template to:
//   1. Create or update the resource group
//   2. Deploy session host resources INTO that resource group via module scoping
//
// Resource file: session-host-resources.bicep (resource-group-scope)
//
// Resources per VM (deployed by resource file):
//   1. Microsoft.HybridCompute/machines               — Arc machine placeholder
//   2. Microsoft.AzureStackHCI/networkInterfaces       — NIC on Azure Local logical network
//   3. Microsoft.AzureStackHCI/VirtualMachineInstances — VM instance (extension resource)
//   4. Microsoft.HybridCompute/machines/extensions     — JsonADDomainExtension (AD join + reboot)
//   5. Microsoft.HybridCompute/machines/extensions     — CustomScriptExtension (AVD agent install)
// =============================================================================

targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters — Resource Group
// ---------------------------------------------------------------------------

@description('Name of the resource group for AVD session host resources. Created if it does not exist.')
param resourceGroupName string

@description('Azure region — must match the Azure Local cluster region')
param location string

// ---------------------------------------------------------------------------
// Parameters — VM Sizing & Count
// ---------------------------------------------------------------------------

@description('Number of session host VMs to deploy')
@minValue(1)
@maxValue(100)
param sessionHostCount int

@description('Session host naming prefix — VMs named {prefix}-001, {prefix}-002, etc.')
param vmNamingPrefix string

@description('Starting index for VM numbering (e.g., 1 → prefix-001)')
param vmStartIndex int = 1

@description('Number of vCPUs per session host')
param vmProcessors int = 4

@description('Memory in MB per session host')
param vmMemoryMB int = 16384

// ---------------------------------------------------------------------------
// Parameters — Azure Local Infrastructure (cross-subscription references)
// ---------------------------------------------------------------------------

@description('Full ARM resource ID of the Azure Local custom location')
param customLocationId string

@description('Full ARM resource ID of the Azure Local logical network for session hosts')
param logicalNetworkId string

@description('Full ARM resource ID of the Azure Local marketplace gallery image')
param galleryImageId string

@description('Full ARM resource ID of the Azure Local storage path (VM config store)')
param storagePathId string

// ---------------------------------------------------------------------------
// Parameters — OS Credentials
// ---------------------------------------------------------------------------

@description('Local administrator username for the session host VMs')
param adminUsername string

@secure()
@description('Local administrator password for the session host VMs')
param adminPassword string

// ---------------------------------------------------------------------------
// Parameters — Domain Join (used by JsonADDomainExtension)
// ---------------------------------------------------------------------------

@description('AD DS domain FQDN (e.g., iic.local)')
param domainFqdn string

@description('Domain join service account — FQDN-qualified (e.g., iic.local\\svc.domainjoin)')
param domainJoinUser string

@secure()
@description('Domain join service account password')
param domainJoinPassword string

@description('Target OU distinguished name (e.g., OU=AVD,DC=iic,DC=local). Empty = default Computers container.')
param domainJoinOUPath string = ''

// ---------------------------------------------------------------------------
// Parameters — AVD Registration
// ---------------------------------------------------------------------------

@secure()
@description('AVD host pool registration token — generated from New-AzWvdRegistrationInfo, valid ~4 hours')
param avdRegistrationToken string

// ---------------------------------------------------------------------------
// Parameters — AVD Agent Download URLs
// ---------------------------------------------------------------------------

@description('Download URL for the AVD Agent MSI')
param avdAgentUrl string = 'https://go.microsoft.com/fwlink/?linkid=2310011'

@description('Download URL for the AVD Bootloader MSI')
param avdBootloaderUrl string = 'https://go.microsoft.com/fwlink/?linkid=2311028'

// ---------------------------------------------------------------------------
// Parameters — Entra ID Authentication (Hybrid Join + SSO)
// ---------------------------------------------------------------------------

@description('Enable Microsoft Entra ID authentication. Installs AADLoginForWindows extension and assigns VM Login RBAC roles.')
param enableEntraIdAuth bool = false

@description('Enroll session hosts in Microsoft Intune via the AAD Login extension. Requires enableEntraIdAuth = true.')
param enrollInIntune bool = false

@description('Object ID of the Entra ID security group for Virtual Machine User Login RBAC role. Empty = skip.')
param entraUserLoginGroupId string = ''

@description('Object ID of the Entra ID security group for Virtual Machine Administrator Login RBAC role. Empty = skip.')
param entraAdminLoginGroupId string = ''

// ---------------------------------------------------------------------------
// Parameters — Tags
// ---------------------------------------------------------------------------

@description('Resource tags applied to the resource group')
param tags object = {}

@description('Enable FSLogix configuration extension deployment')
param enableFslogix bool = false

@description('FSLogix profile share UNC path')
param fslogixProfileSharePath string = ''

@description('FSLogix profile container size in MB')
param fslogixSizeInMBs int = 30720

var fslogixMachineNames = [for i in range(0, sessionHostCount): '${vmNamingPrefix}-${padLeft(string(vmStartIndex + i), 3, '0')}']

// ---------------------------------------------------------------------------
// Resource Group — created at subscription scope
// ---------------------------------------------------------------------------

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// ---------------------------------------------------------------------------
// Module — deploy session host resources into the resource group
// ---------------------------------------------------------------------------

module sessionHosts './session-host-resources.bicep' = {
  scope: rg
  name: 'avd-session-hosts-${uniqueString(resourceGroupName, vmNamingPrefix)}'
  params: {
    sessionHostCount: sessionHostCount
    vmNamingPrefix: vmNamingPrefix
    vmStartIndex: vmStartIndex
    location: location
    vmProcessors: vmProcessors
    vmMemoryMB: vmMemoryMB
    customLocationId: customLocationId
    logicalNetworkId: logicalNetworkId
    galleryImageId: galleryImageId
    storagePathId: storagePathId
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainFqdn: domainFqdn
    domainJoinUser: domainJoinUser
    domainJoinPassword: domainJoinPassword
    domainJoinOUPath: domainJoinOUPath
    avdRegistrationToken: avdRegistrationToken
    avdAgentUrl: avdAgentUrl
    avdBootloaderUrl: avdBootloaderUrl
    enableEntraIdAuth: enableEntraIdAuth
    enrollInIntune: enrollInIntune
    entraUserLoginGroupId: entraUserLoginGroupId
    entraAdminLoginGroupId: entraAdminLoginGroupId
  }
}

module fslogix './fslogix.bicep' = if (enableFslogix && !empty(fslogixProfileSharePath)) {
  scope: rg
  name: 'avd-fslogix-${uniqueString(resourceGroupName, vmNamingPrefix)}'
  params: {
    location: location
    machineNames: fslogixMachineNames
    profileSharePath: fslogixProfileSharePath
    sizeInMBs: fslogixSizeInMBs
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output resourceGroupName string = rg.name
output deployedVMs array = sessionHosts.outputs.deployedVMs
