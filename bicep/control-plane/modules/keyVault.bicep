// modules/keyVault.bicep

@description('Key Vault name (must be globally unique, 3-24 alphanumeric and hyphens).')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object = {}

var tenantId = subscription().tenantId

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
  }
}

output keyVaultId string = kv.id
output keyVaultUri string = kv.properties.vaultUri
