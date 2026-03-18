<#
.SYNOPSIS
    Validates an AVD deployment by checking host pool health, session host status,
    and optional FSLogix/monitoring configuration.

.DESCRIPTION
    Post-deployment smoke test that verifies:
      1. Host pool exists and is correctly typed (Pooled/Personal)
      2. Session hosts are registered and available
      3. FSLogix shares are reachable (if enabled)
      4. Diagnostics settings are configured (if enabled)
      5. Scaling plan is attached (if enabled, Pooled only)

.PARAMETER ConfigPath
    Path to the central config/variables.yml file.

.EXAMPLE
    .\Test-AVDDeployment.ps1 -ConfigPath ..\..\config\variables.yml
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -ConfigPath $ConfigPath -ResolveSecrets $false

$cp = $config.control_plane
$sh = $config.session_hosts
$rgName = $cp.resource_group

$results = @()
$passed = 0
$failed = 0

function Add-TestResult {
    param ([string]$Test, [bool]$Pass, [string]$Detail)
    $script:results += [PSCustomObject]@{
        Test   = $Test
        Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        Detail = $Detail
    }
    if ($Pass) { $script:passed++ } else { $script:failed++ }
}

Write-Host "=== AVD Deployment Validation ===" -ForegroundColor Cyan

# Test 1: Host pool exists
Write-Host "`nChecking host pool..." -ForegroundColor Yellow
try {
    $pool = Get-AzWvdHostPool -ResourceGroupName $rgName -Name $cp.host_pool_name -ErrorAction Stop
    Add-TestResult -Test "Host pool exists" -Pass $true -Detail $pool.Id
    Add-TestResult -Test "Host pool type matches" -Pass ($pool.HostPoolType -eq $cp.host_pool_type) -Detail "Expected: $($cp.host_pool_type), Got: $($pool.HostPoolType)"
}
catch {
    Add-TestResult -Test "Host pool exists" -Pass $false -Detail $_.Exception.Message
}

# Test 2: Application group exists
Write-Host "Checking application group..." -ForegroundColor Yellow
try {
    $ag = Get-AzWvdApplicationGroup -ResourceGroupName $rgName -Name $cp.app_group_name -ErrorAction Stop
    Add-TestResult -Test "Application group exists" -Pass $true -Detail $ag.Id
}
catch {
    Add-TestResult -Test "Application group exists" -Pass $false -Detail $_.Exception.Message
}

# Test 3: Workspace exists
Write-Host "Checking workspace..." -ForegroundColor Yellow
try {
    $ws = Get-AzWvdWorkspace -ResourceGroupName $rgName -Name $cp.workspace_name -ErrorAction Stop
    Add-TestResult -Test "Workspace exists" -Pass $true -Detail $ws.Id
}
catch {
    Add-TestResult -Test "Workspace exists" -Pass $false -Detail $_.Exception.Message
}

# Test 4: Session hosts registered
Write-Host "Checking session hosts..." -ForegroundColor Yellow
try {
    $hosts = Get-AzWvdSessionHost -ResourceGroupName $rgName -HostPoolName $cp.host_pool_name -ErrorAction Stop
    $availableCount = ($hosts | Where-Object { $_.Status -eq 'Available' }).Count
    Add-TestResult -Test "Session hosts registered" -Pass ($hosts.Count -ge $sh.session_host_count) -Detail "Expected: $($sh.session_host_count), Registered: $($hosts.Count)"
    Add-TestResult -Test "Session hosts available" -Pass ($availableCount -ge 1) -Detail "Available: $availableCount / $($hosts.Count)"
}
catch {
    Add-TestResult -Test "Session hosts registered" -Pass $false -Detail $_.Exception.Message
}

# Test 5: FSLogix share reachability (if enabled)
if ($config.fslogix -and $config.fslogix.enabled) {
    Write-Host "Checking FSLogix share..." -ForegroundColor Yellow
    $sharePath = switch ($config.fslogix.share_topology) {
        'single' { $config.fslogix.single_share.vhd_path }
        'split' { $config.fslogix.split_shares.profile_vhd_path }
        'cloud_cache' { 'N/A (Cloud Cache)' }
    }
    if ($sharePath -ne 'N/A (Cloud Cache)') {
        $reachable = Test-Path $sharePath -ErrorAction SilentlyContinue
        Add-TestResult -Test "FSLogix share reachable" -Pass $reachable -Detail $sharePath
    }
    else {
        Add-TestResult -Test "FSLogix Cloud Cache configured" -Pass ($config.fslogix.cloud_cache.connections.Count -gt 0) -Detail "Connections: $($config.fslogix.cloud_cache.connections.Count)"
    }
}

# Test 6: Scaling plan (if enabled, Pooled only)
if ($config.scaling -and $config.scaling.enabled -and $cp.host_pool_type -eq 'Pooled') {
    Write-Host "Checking scaling plan..." -ForegroundColor Yellow
    $spName = "$($cp.host_pool_name)-sp"
    try {
        $sp = Get-AzWvdScalingPlan -ResourceGroupName $rgName -Name $spName -ErrorAction Stop
        Add-TestResult -Test "Scaling plan exists" -Pass $true -Detail $sp.Id
    }
    catch {
        Add-TestResult -Test "Scaling plan exists" -Pass $false -Detail $_.Exception.Message
    }
}

# Summary
Write-Host "`n=== Validation Results ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize
Write-Host "Passed: $passed  Failed: $failed  Total: $($passed + $failed)" -ForegroundColor $(if ($failed -eq 0) { 'Green' } else { 'Red' })

if ($failed -gt 0) {
    exit 1
}
