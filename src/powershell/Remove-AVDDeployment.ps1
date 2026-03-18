<#
.SYNOPSIS
    Tears down an AVD deployment — removes session hosts, control plane, and optionally resource groups.

.DESCRIPTION
    Removes AVD resources in reverse dependency order:
      1. Scaling plan (if exists)
      2. Session host VMs (Arc machines + extensions)
      3. Application group
      4. Workspace
      5. Host pool
      6. Resource groups (if -RemoveResourceGroups is specified)

    All operations use ShouldProcess — use -WhatIf for dry-run.

.PARAMETER ConfigPath
    Path to the central config/variables.yml file.

.PARAMETER RemoveResourceGroups
    Also delete the resource groups. Default: $false (removes resources only).

.EXAMPLE
    .\Remove-AVDDeployment.ps1 -ConfigPath ..\..\config\variables.yml -WhatIf

.EXAMPLE
    .\Remove-AVDDeployment.ps1 -ConfigPath ..\..\config\variables.yml -RemoveResourceGroups -Confirm
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param (
    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [Parameter()]
    [switch]$RemoveResourceGroups
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -ConfigPath $ConfigPath -ResolveSecrets $false

$cp = $config.control_plane
$sh = $config.session_hosts
$sub = $config.subscription
$cpRg = $cp.resource_group
$shRg = $sh.resource_group

Write-Host "=== AVD Deployment Removal ===" -ForegroundColor Red
Write-Host "  Control Plane RG : $cpRg" -ForegroundColor Gray
Write-Host "  Session Host RG  : $shRg" -ForegroundColor Gray
Write-Host ""

# Step 1: Remove scaling plan
if ($cp.host_pool_type -eq 'Pooled') {
    $spName = "$($cp.host_pool_name)-sp"
    $sp = Get-AzWvdScalingPlan -ResourceGroupName $cpRg -Name $spName -ErrorAction SilentlyContinue
    if ($sp) {
        if ($PSCmdlet.ShouldProcess($spName, 'Remove scaling plan')) {
            Remove-AzWvdScalingPlan -ResourceGroupName $cpRg -Name $spName
            Write-Host "  Scaling plan '$spName' removed." -ForegroundColor Yellow
        }
    }
}

# Step 2: Remove session host VMs
$prefix = $sh.vm_naming_prefix
$count = $sh.session_host_count
$startIndex = if ($sh.vm_start_index) { $sh.vm_start_index } else { 1 }

for ($i = $startIndex; $i -lt ($startIndex + $count); $i++) {
    $vmName = '{0}-{1:D3}' -f $prefix, $i

    # Unregister from host pool first
    $sessionHostName = "$vmName.$($config.domain.domain_fqdn)"
    $existingSh = Get-AzWvdSessionHost -ResourceGroupName $cpRg -HostPoolName $cp.host_pool_name -Name $sessionHostName -ErrorAction SilentlyContinue
    if ($existingSh) {
        if ($PSCmdlet.ShouldProcess($sessionHostName, 'Remove session host registration')) {
            Remove-AzWvdSessionHost -ResourceGroupName $cpRg -HostPoolName $cp.host_pool_name -Name $sessionHostName
            Write-Host "  Session host '$sessionHostName' unregistered." -ForegroundColor Yellow
        }
    }

    # Remove Arc machine
    $machine = Get-AzResource -ResourceGroupName $shRg -Name $vmName -ResourceType 'Microsoft.HybridCompute/machines' -ErrorAction SilentlyContinue
    if ($machine) {
        if ($PSCmdlet.ShouldProcess($vmName, 'Remove Arc machine')) {
            Remove-AzResource -ResourceId $machine.ResourceId -Force
            Write-Host "  Arc machine '$vmName' removed." -ForegroundColor Yellow
        }
    }

    # Remove NIC
    $nicName = "$vmName-nic"
    $nic = Get-AzResource -ResourceGroupName $shRg -Name $nicName -ResourceType 'Microsoft.AzureStackHCI/networkInterfaces' -ErrorAction SilentlyContinue
    if ($nic) {
        if ($PSCmdlet.ShouldProcess($nicName, 'Remove NIC')) {
            Remove-AzResource -ResourceId $nic.ResourceId -Force
            Write-Host "  NIC '$nicName' removed." -ForegroundColor Yellow
        }
    }
}

# Step 3: Remove workspace
$ws = Get-AzWvdWorkspace -ResourceGroupName $cpRg -Name $cp.workspace_name -ErrorAction SilentlyContinue
if ($ws) {
    if ($PSCmdlet.ShouldProcess($cp.workspace_name, 'Remove workspace')) {
        Remove-AzWvdWorkspace -ResourceGroupName $cpRg -Name $cp.workspace_name
        Write-Host "  Workspace '$($cp.workspace_name)' removed." -ForegroundColor Yellow
    }
}

# Step 4: Remove application group
$ag = Get-AzWvdApplicationGroup -ResourceGroupName $cpRg -Name $cp.app_group_name -ErrorAction SilentlyContinue
if ($ag) {
    if ($PSCmdlet.ShouldProcess($cp.app_group_name, 'Remove application group')) {
        Remove-AzWvdApplicationGroup -ResourceGroupName $cpRg -Name $cp.app_group_name
        Write-Host "  Application group '$($cp.app_group_name)' removed." -ForegroundColor Yellow
    }
}

# Step 5: Remove host pool
$pool = Get-AzWvdHostPool -ResourceGroupName $cpRg -Name $cp.host_pool_name -ErrorAction SilentlyContinue
if ($pool) {
    if ($PSCmdlet.ShouldProcess($cp.host_pool_name, 'Remove host pool')) {
        Remove-AzWvdHostPool -ResourceGroupName $cpRg -Name $cp.host_pool_name
        Write-Host "  Host pool '$($cp.host_pool_name)' removed." -ForegroundColor Yellow
    }
}

# Step 6: Remove resource groups (optional)
if ($RemoveResourceGroups) {
    foreach ($rg in @($cpRg, $shRg) | Select-Object -Unique) {
        $rgObj = Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue
        if ($rgObj) {
            if ($PSCmdlet.ShouldProcess($rg, 'Remove resource group')) {
                Remove-AzResourceGroup -Name $rg -Force
                Write-Host "  Resource group '$rg' removed." -ForegroundColor Yellow
            }
        }
    }
}

Write-Host "`n=== AVD Deployment Removal Complete ===" -ForegroundColor Green
