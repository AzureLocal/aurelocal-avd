// modules/hostPool.bicep

@description('Host pool name.')
param name string

@description('Azure region.')
param location string

@description('Host pool type: Pooled or Personal.')
@allowed(['Pooled', 'Personal'])
param hostPoolType string = 'Pooled'

@description('Load-balancer type for Pooled host pools.')
@allowed(['BreadthFirst', 'DepthFirst'])
param loadBalancerType string = 'BreadthFirst'

@description('Maximum sessions per host (Pooled only).')
param maxSessionLimit int = 10

@description('Resource tags.')
param tags object = {}

resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2023-09-05' = {
  name: name
  location: location
  tags: tags
  properties: {
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: hostPoolType == 'Pooled' ? maxSessionLimit : 1
    startVMOnConnect: true
    registrationInfo: {
      expirationTime: dateTimeAdd(utcNow(), 'PT24H')
      registrationTokenOperation: 'Update'
    }
  }
}

output hostPoolId string = hostPool.id
output registrationToken string = hostPool.properties.registrationInfo.token
