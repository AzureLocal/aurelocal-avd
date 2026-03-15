# Control-plane parameters – copy to parameters.ps1 and fill in your values.
# DO NOT commit parameters.ps1 (it is .gitignore'd).

$ResourceGroupName         = 'rg-avd-prod'
$Location                  = 'eastus'
$HostPoolName              = 'hp-azurelocal-pool01'
$HostPoolType              = 'Pooled'           # Pooled | Personal
$LoadBalancerType          = 'BreadthFirst'     # BreadthFirst | DepthFirst
$MaxSessionLimit           = 10
$WorkspaceName             = 'ws-avd-prod'
$AppGroupName              = 'ag-avd-desktops'
$KeyVaultName              = 'kv-avd-prod-001'  # Must be globally unique
$LogAnalyticsWorkspaceName = 'law-avd-prod'
$EnvironmentTag            = 'production'
$OwnerTag                  = 'platform-team'
