// =============================================================================
// AVD Networking — Bicep
// =============================================================================
// NSG with AVD-required outbound rules and optional private endpoints.
// =============================================================================

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Azure region')
param location string

@description('Name for the NSG')
param nsgName string

@description('Enable NSG creation')
param nsgEnabled bool = true

@description('Enable private endpoints')
param privateEndpointsEnabled bool = false

@description('Host pool name (used for private endpoint naming)')
param hostPoolName string

@description('Resource ID of the host pool')
param hostPoolId string

@description('Workspace name')
param workspaceName string

@description('Resource ID of the workspace')
param workspaceId string

@description('Subnet resource ID for private endpoints')
param privateEndpointSubnetId string = ''

@description('Private DNS zone resource ID for AVD private link')
param privateDnsZoneId string = ''

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// NSG
// ---------------------------------------------------------------------------

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-05-01' = if (nsgEnabled) {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-AVD-Service'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'WindowsVirtualDesktop'
        }
      }
      {
        name: 'Allow-AzureMonitor'
        properties: {
          priority: 110
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureMonitor'
        }
      }
      {
        name: 'Allow-AzureAD'
        properties: {
          priority: 120
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureActiveDirectory'
        }
      }
      {
        name: 'Allow-KMS'
        properties: {
          priority: 130
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1688'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Private Endpoints
// ---------------------------------------------------------------------------

resource hostPoolPe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (privateEndpointsEnabled) {
  name: '${hostPoolName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${hostPoolName}-psc'
        properties: {
          privateLinkServiceId: hostPoolId
          groupIds: ['connection']
        }
      }
    ]
  }
}

resource hostPoolPeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (privateEndpointsEnabled && !empty(privateDnsZoneId)) {
  parent: hostPoolPe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

resource workspacePe 'Microsoft.Network/privateEndpoints@2023-05-01' = if (privateEndpointsEnabled) {
  name: '${workspaceName}-pe'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${workspaceName}-psc'
        properties: {
          privateLinkServiceId: workspaceId
          groupIds: ['feed']
        }
      }
    ]
  }
}

resource workspacePeDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (privateEndpointsEnabled && !empty(privateDnsZoneId)) {
  parent: workspacePe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output nsgId string = nsgEnabled ? nsg.id : ''
output nsgName string = nsgEnabled ? nsg.name : ''
