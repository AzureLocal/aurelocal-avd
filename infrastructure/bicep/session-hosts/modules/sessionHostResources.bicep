// =============================================================================
// AVD Session Host on Azure Local — Cross-Subscription Bicep Deployment
// =============================================================================
// Deploys N session host VMs onto an Azure Local cluster where the VM resources
// live in a DIFFERENT subscription from the Azure Local infrastructure.
//
// Why Bicep/ARM works cross-subscription:
//   az deployment group create sends the template directly to Azure Resource
//   Manager, which resolves resource IDs globally. The az stack-hci-vm CLI
//   and AVD portal wizard fail because they enforce client-side subscription
//   scope checks before the request reaches ARM.
//
// Resources per VM (5 per VM):
//   1. Microsoft.HybridCompute/machines               — Arc machine placeholder
//   2. Microsoft.AzureStackHCI/networkInterfaces       — NIC on Azure Local logical network
//   3. Microsoft.AzureStackHCI/VirtualMachineInstances — VM instance (extension resource)
//   4. Microsoft.HybridCompute/machines/extensions     — JsonADDomainExtension (AD join + reboot)
//   5. Microsoft.HybridCompute/machines/extensions     — CustomScriptExtension (AVD agent install)
//
// Two-extension pattern (matches Azure portal behavior):
//   Extension 1: JsonADDomainExtension handles domain join and automatic reboot.
//                This is the same extension the Azure portal uses when "Enable
//                domain join" is checked during VM creation. It uses DJOIN under
//                the hood — no PowerShell Add-Computer or manual reboot needed.
//                Ref: https://learn.microsoft.com/azure/azure-local/manage/create-arc-virtual-machines
//   Extension 2: CustomScriptExtension runs AFTER domain join completes and VM
//                reboots. Downloads + installs AVD Agent (with registration token)
//                and AVD Bootloader. No reboot needed — agent self-registers with
//                the host pool broker.
// =============================================================================

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

@description('Azure region — must match the Azure Local cluster region')
param location string

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

@description('Enable Microsoft Entra ID authentication. Installs AADLoginForWindows extension on each session host for SSO. Session hosts must be Hybrid Azure AD Joined.')
param enableEntraIdAuth bool = false

@description('Enroll session hosts in Microsoft Intune via the AAD Login extension. Requires enableEntraIdAuth = true.')
param enrollInIntune bool = false

@description('Object ID of the Entra ID security group to assign the Virtual Machine User Login role on this resource group. Empty = skip assignment.')
param entraUserLoginGroupId string = ''

@description('Object ID of the Entra ID security group to assign the Virtual Machine Administrator Login role on this resource group. Empty = skip assignment.')
param entraAdminLoginGroupId string = ''

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------

// CSE command — AVD agent install ONLY (domain join handled by JsonADDomainExtension).
// By the time this runs, the VM is already domain-joined and rebooted.
// Sequence: enforce TLS 1.2 → download agents → install Agent w/ token → install Bootloader
var cseCommand = 'powershell -ExecutionPolicy Bypass -Command "$ErrorActionPreference=\'Stop\';try{[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;Invoke-WebRequest -Uri \'${avdAgentUrl}\' -OutFile C:\\AVDAgent.msi -UseBasicParsing;Invoke-WebRequest -Uri \'${avdBootloaderUrl}\' -OutFile C:\\AVDBootloader.msi -UseBasicParsing;$r=Start-Process msiexec -ArgumentList \'/i C:\\AVDAgent.msi /quiet /norestart REGISTRATIONTOKEN=${avdRegistrationToken}\' -Wait -PassThru;if($r.ExitCode -ne 0){throw (\'Agent exit code: \'+$r.ExitCode)};$r=Start-Process msiexec -ArgumentList \'/i C:\\AVDBootloader.msi /quiet /norestart\' -Wait -PassThru;if($r.ExitCode -ne 0){throw (\'Bootloader exit code: \'+$r.ExitCode)}}catch{$_|Out-File C:\\avd-setup-error.log -Encoding utf8;throw}"'

// ---------------------------------------------------------------------------
// Resources — Loop over sessionHostCount
// ---------------------------------------------------------------------------

// Generate padded VM names: prefix-001, prefix-002, etc.
resource arcMachines 'Microsoft.HybridCompute/machines@2023-06-20-preview' = [for i in range(0, sessionHostCount): {
  name: '${vmNamingPrefix}-${padLeft(string(vmStartIndex + i), 3, '0')}'
  location: location
  kind: 'HCI'
  identity: {
    type: 'SystemAssigned'
  }
}]

resource nics 'Microsoft.AzureStackHCI/networkInterfaces@2025-09-01-preview' = [for i in range(0, sessionHostCount): {
  name: '${vmNamingPrefix}-${padLeft(string(vmStartIndex + i), 3, '0')}-nic'
  location: location
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    ipConfigurations: [
      {
        name: '${vmNamingPrefix}-${padLeft(string(vmStartIndex + i), 3, '0')}-nic'
        properties: {
          subnet: {
            id: logicalNetworkId
          }
        }
      }
    ]
  }
}]

resource vmInstances 'Microsoft.AzureStackHCI/virtualMachineInstances@2025-09-01-preview' = [for i in range(0, sessionHostCount): {
  name: 'default'
  scope: arcMachines[i]
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  dependsOn: [
    nics[i]
  ]
  properties: {
    osProfile: {
      adminUsername: adminUsername
      adminPassword: adminPassword
      computerName: '${vmNamingPrefix}-${padLeft(string(vmStartIndex + i), 3, '0')}'
      windowsConfiguration: {
        provisionVMAgent: true
        provisionVMConfigAgent: true
      }
    }
    hardwareProfile: {
      vmSize: 'Default'
      processors: vmProcessors
      memoryMB: vmMemoryMB
    }
    storageProfile: {
      imageReference: {
        id: galleryImageId
      }
      vmConfigStoragePathId: storagePathId
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nics[i].id
        }
      ]
    }
  }
}]

// Extension 1: JsonADDomainExtension — Active Directory domain join
// Matches the pattern used by the Azure portal "Enable domain join" option.
// Options value 3 = NETSETUP_JOIN_DOMAIN (0x1) | NETSETUP_ACCT_CREATE (0x2)
// The extension handles reboot automatically when Restart = true.
resource domainJoinExtensions 'Microsoft.HybridCompute/machines/extensions@2023-06-20-preview' = [for i in range(0, sessionHostCount): {
  parent: arcMachines[i]
  name: 'JsonADDomainExtension'
  location: location
  dependsOn: [
    vmInstances[i]
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainFqdn
      OUPath: domainJoinOUPath
      User: domainJoinUser
      Restart: true
      Options: 3
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}]

// Extension 2: CustomScriptExtension — AVD Agent + Bootloader install
// Runs after domain join completes and the VM reboots.
// Downloads and installs the AVD Agent (with registration token) and Bootloader.
// No reboot needed — the agent self-registers with the AVD host pool broker.
resource avdAgentExtensions 'Microsoft.HybridCompute/machines/extensions@2023-06-20-preview' = [for i in range(0, sessionHostCount): {
  parent: arcMachines[i]
  name: 'AVDAgentInstall'
  location: location
  dependsOn: [
    domainJoinExtensions[i]
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {}
    protectedSettings: {
      commandToExecute: cseCommand
    }
  }
}]

// Extension 3 (conditional): AADLoginForWindows — Entra ID SSO for hybrid-joined session hosts
// Enables single sign-on via Microsoft Entra ID so users authenticate with their Entra credentials.
// When enrollInIntune = true, the extension also registers the device with Intune MDM.
// Depends on: AVD agent install (Extension 2) must complete first.
// Ref: https://learn.microsoft.com/azure/virtual-desktop/configure-single-sign-on
resource entraIdLoginExtensions 'Microsoft.HybridCompute/machines/extensions@2023-06-20-preview' = [for i in range(0, sessionHostCount): if (enableEntraIdAuth) {
  parent: arcMachines[i]
  name: 'AADLoginForWindows'
  location: location
  dependsOn: [
    avdAgentExtensions[i]
  ]
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: enrollInIntune ? {
      mdmId: '0000000a-0000-0000-c000-000000000000'
    } : {}
  }
}]

// ---------------------------------------------------------------------------
// RBAC — Entra ID VM Login Roles (conditional)
// ---------------------------------------------------------------------------
// Virtual Machine User Login      — allows standard Entra users to RDP sign-in
// Virtual Machine Administrator Login — allows Entra users to sign-in with local admin rights
// Scoped to this resource group so they apply to all session host Arc machines.
// Only deployed when enableEntraIdAuth = true AND a group Object ID is provided.

var vmUserLoginRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'fb879df8-f326-4884-b1cf-06f3ad86be52')
var vmAdminLoginRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '1c0163c0-47e6-4577-8991-ea5c82e286e4')

resource vmUserLoginAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableEntraIdAuth && !empty(entraUserLoginGroupId)) {
  name: guid(resourceGroup().id, entraUserLoginGroupId, vmUserLoginRoleId)
  properties: {
    roleDefinitionId: vmUserLoginRoleId
    principalId: entraUserLoginGroupId
    principalType: 'Group'
  }
}

resource vmAdminLoginAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (enableEntraIdAuth && !empty(entraAdminLoginGroupId)) {
  name: guid(resourceGroup().id, entraAdminLoginGroupId, vmAdminLoginRoleId)
  properties: {
    roleDefinitionId: vmAdminLoginRoleId
    principalId: entraAdminLoginGroupId
    principalType: 'Group'
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output deployedVMs array = [for i in range(0, sessionHostCount): {
  vmName: arcMachines[i].name
  arcMachineId: arcMachines[i].id
  nicName: nics[i].name
  nicId: nics[i].id
}]
