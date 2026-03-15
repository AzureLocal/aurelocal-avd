// bicep/session-hosts/main.bicep
// Deploys AVD session-host VMs on an Azure Local cluster.
// Scope: resource group
//
// Deploy with:
//   az deployment group create \
//     --resource-group <rg> \
//     --template-file main.bicep \
//     --parameters main.bicepparam

targetScope = 'resourceGroup'

// ── Parameters ────────────────────────────────────────────────────────────────

@description('Resource ID of the Arc Custom Location for the Azure Local cluster.')
param customLocationId string

@description('Azure region (must match the custom location region).')
param location string

@description('Prefix for session-host VM names (e.g. avd-sh → avd-sh-01, avd-sh-02).')
param vmNamePrefix string = 'avd-sh'

@description('Number of session-host VMs to deploy.')
param vmCount int = 2

@description('Azure Local VM size.')
param vmSize string = 'Standard_D4s_v3'

@description('Resource ID of the Azure Local gallery image.')
param imageId string

@description('Resource ID of the Azure Local virtual network.')
param vnetId string

@description('Subnet name within the VNet.')
param subnetName string = 'default'

@description('AVD host-pool registration token (store in Key Vault and reference via keyvault() function in .bicepparam).')
@secure()
param registrationToken string

@description('Fully-qualified domain name to join (e.g. contoso.local).')
param domainFqdn string

@description('UPN of the domain-join service account.')
param domainJoinUser string

@description('Password for the domain-join service account.')
@secure()
param domainJoinPassword string

@description('OU path for the computer account.')
param ouPath string = ''

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

// ── Session Hosts ─────────────────────────────────────────────────────────────

module sessionHosts 'modules/sessionHost.bicep' = [for i in range(1, vmCount): {
  name: 'deploy-sh-${vmNamePrefix}-${padLeft(i, 2, '0')}'
  params: {
    vmName: '${vmNamePrefix}-${padLeft(i, 2, '0')}'
    location: location
    customLocationId: customLocationId
    vmSize: vmSize
    imageId: imageId
    vnetId: vnetId
    subnetName: subnetName
    registrationToken: registrationToken
    domainFqdn: domainFqdn
    domainJoinUser: domainJoinUser
    domainJoinPassword: domainJoinPassword
    ouPath: ouPath
    tags: tags
  }
}]

// ── Outputs ───────────────────────────────────────────────────────────────────

output sessionHostNames array = [for i in range(1, vmCount): '${vmNamePrefix}-${padLeft(i, 2, '0')}']
