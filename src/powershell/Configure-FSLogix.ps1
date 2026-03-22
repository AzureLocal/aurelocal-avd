<#
.SYNOPSIS
    Configures FSLogix profile containers on AVD session hosts.

.DESCRIPTION
    Applies FSLogix registry settings to session host VMs via Arc machine
    extensions. Supports three share topologies:
      - single:      One VHDx container on a single SMB share
      - split:       Separate shares for profile and Office containers
      - cloud_cache: Multi-site replication via Cloud Cache provider list

    Registry keys applied under HKLM:\SOFTWARE\FSLogix\Profiles and
    HKLM:\SOFTWARE\Policies\FSLogix\ODFC (for Office containers).

.PARAMETER ConfigPath
    Path to the central config/variables.yml file.

.EXAMPLE
    .\Configure-FSLogix.ps1 -ConfigPath ..\..\config\variables.yml
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -ConfigPath $ConfigPath -ResolveSecrets $false

if (-not $config.fslogix -or -not $config.fslogix.enabled) {
    Write-Host "FSLogix is disabled in configuration — skipping." -ForegroundColor DarkYellow
    return
}

$fslogix = $config.fslogix
$sessionHosts = $config.session_hosts
$rgName = $sessionHosts.resource_group
$prefix = $sessionHosts.vm_naming_prefix
$count = $sessionHosts.session_host_count
$startIndex = if ($sessionHosts.vm_start_index) { $sessionHosts.vm_start_index } else { 1 }

Write-Host "=== FSLogix Configuration ===" -ForegroundColor Cyan
Write-Host "  Topology: $($fslogix.share_topology)" -ForegroundColor Gray

# Build registry commands based on topology
$regCommands = @()

# Common profile container settings
$pc = $fslogix.profile_container
$regCommands += 'New-Item -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Force | Out-Null'
$regCommands += 'Set-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -Value 1 -Type DWord'
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'SizeInMBs' -Value $($pc.size_in_mb) -Type DWord"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VolumeType' -Value '$($pc.vhd_type)' -Type String"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'FlipFlopProfileDirectoryName' -Value $(if ($pc.flip_flop_enabled) { 1 } else { 0 }) -Type DWord"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'DeleteLocalProfileWhenVHDShouldApply' -Value $(if ($pc.delete_on_logoff) { 1 } else { 0 }) -Type DWord"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'IsDynamic' -Value $(if ($pc.is_dynamic) { 1 } else { 0 }) -Type DWord"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'LockedRetryCount' -Value $($pc.locked_retry_count) -Type DWord"
$regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'LockedRetryInterval' -Value $($pc.locked_retry_interval) -Type DWord"

switch ($fslogix.share_topology) {
    'single' {
        $vhdPath = $fslogix.single_share.vhd_path
        $regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -Value '$vhdPath' -Type MultiString"
    }
    'split' {
        $profilePath = $fslogix.split_shares.profile_vhd_path
        $officePath = $fslogix.split_shares.office_vhd_path
        $regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'VHDLocations' -Value '$profilePath' -Type MultiString"
        # Office Data File Container (ODFC)
        $regCommands += 'New-Item -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Force | Out-Null'
        $regCommands += 'Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\FSLogix\ODFC" -Name "Enabled" -Value 1 -Type DWord'
        $regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC' -Name 'VHDLocations' -Value '$officePath' -Type MultiString"
        $regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\FSLogix\ODFC' -Name 'VolumeType' -Value '$($pc.vhd_type)' -Type String"
    }
    'cloud_cache' {
        $ccList = $fslogix.cloud_cache.connections -join ','
        $regCommands += "Set-ItemProperty -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Name 'CCDLocations' -Value '$ccList' -Type MultiString"
    }
}

$scriptBlock = $regCommands -join '; '

# Apply to each session host via Arc extension
for ($i = $startIndex; $i -lt ($startIndex + $count); $i++) {
    $vmName = '{0}-{1:D3}' -f $prefix, $i

    Write-Host "`nConfiguring FSLogix on '$vmName'..." -ForegroundColor Yellow

    if (-not $PSCmdlet.ShouldProcess($vmName, 'Configure FSLogix registry')) {
        continue
    }

    try {
        Set-AzVMExtension `
            -ResourceGroupName $rgName `
            -VMName $vmName `
            -Name 'FSLogixConfig' `
            -Publisher 'Microsoft.Compute' `
            -ExtensionType 'CustomScriptExtension' `
            -TypeHandlerVersion '1.10' `
            -Settings @{} `
            -ProtectedSettings @{
                commandToExecute = "powershell -ExecutionPolicy Bypass -Command `"$scriptBlock`""
            } | Out-Null
        Write-Host "  FSLogix configured on '$vmName'." -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to configure FSLogix on '$vmName': $_"
    }
}

Write-Host "`n=== FSLogix Configuration Complete ===" -ForegroundColor Green
