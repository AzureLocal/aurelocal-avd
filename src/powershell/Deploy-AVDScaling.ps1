<#
.SYNOPSIS
    Deploys an AVD scaling plan for Pooled host pools.

.DESCRIPTION
    Creates an AVD scaling plan with ramp-up, peak, ramp-down, and off-peak
    schedules from config/variables.yml. The scaling plan is assigned to the
    host pool automatically.

    Only applies to Pooled host pools — exits cleanly for Personal.

.PARAMETER ConfigPath
    Path to the central config/variables.yml file.

.EXAMPLE
    .\Deploy-AVDScaling.ps1 -ConfigPath ..\..\config\variables.yml
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

# Validate preconditions
if ($config.control_plane.host_pool_type -ne 'Pooled') {
    Write-Host "Scaling plans only apply to Pooled host pools — skipping." -ForegroundColor DarkYellow
    return
}

if (-not $config.scaling -or -not $config.scaling.enabled) {
    Write-Host "Scaling is disabled in configuration — skipping." -ForegroundColor DarkYellow
    return
}

$scaling = $config.scaling
$cp = $config.control_plane
$sub = $config.subscription
$rgName = $cp.resource_group
$hostPoolName = $cp.host_pool_name
$scalingPlanName = "$hostPoolName-sp"

Write-Host "=== AVD Scaling Plan Deployment ===" -ForegroundColor Cyan
Write-Host "  Scaling Plan : $scalingPlanName" -ForegroundColor Gray
Write-Host "  Host Pool    : $hostPoolName" -ForegroundColor Gray
Write-Host "  Time Zone    : $($scaling.time_zone)" -ForegroundColor Gray

# Build schedule objects
$schedules = @()
foreach ($sched in $scaling.schedules) {
    $scheduleObj = @{
        Name             = $sched.name
        DaysOfWeek       = $sched.days_of_week
    }

    if ($sched.ramp_up) {
        $scheduleObj['RampUpStartTime']                = [DateTime]::ParseExact($sched.ramp_up.start_time, 'HH:mm', $null)
        $scheduleObj['RampUpLoadBalancingAlgorithm']    = $sched.ramp_up.load_balancer_type
        $scheduleObj['RampUpMinimumHostsPct']           = $sched.ramp_up.minimum_host_percent
        $scheduleObj['RampUpCapacityThresholdPct']      = $sched.ramp_up.capacity_threshold_percent
    }

    if ($sched.peak) {
        $scheduleObj['PeakStartTime']                  = [DateTime]::ParseExact($sched.peak.start_time, 'HH:mm', $null)
        $scheduleObj['PeakLoadBalancingAlgorithm']     = $sched.peak.load_balancer_type
    }

    if ($sched.ramp_down) {
        $scheduleObj['RampDownStartTime']              = [DateTime]::ParseExact($sched.ramp_down.start_time, 'HH:mm', $null)
        $scheduleObj['RampDownLoadBalancingAlgorithm']  = $sched.ramp_down.load_balancer_type
        $scheduleObj['RampDownMinimumHostsPct']         = $sched.ramp_down.minimum_host_percent
        $scheduleObj['RampDownCapacityThresholdPct']    = $sched.ramp_down.capacity_threshold_percent
        $scheduleObj['RampDownForceLogoffUser']         = $sched.ramp_down.force_logoff
        $scheduleObj['RampDownWaitTimeMinute']          = $sched.ramp_down.wait_time_minutes
        $scheduleObj['RampDownNotificationMessage']     = $sched.ramp_down.notification_message
        $scheduleObj['RampDownStopHostsWhen']           = 'ZeroSessions'
    }

    if ($sched.off_peak) {
        $scheduleObj['OffPeakStartTime']               = [DateTime]::ParseExact($sched.off_peak.start_time, 'HH:mm', $null)
        $scheduleObj['OffPeakLoadBalancingAlgorithm']   = $sched.off_peak.load_balancer_type
    }

    $schedules += [Microsoft.Azure.PowerShell.Cmdlets.DesktopVirtualization.Models.Api20210903Preview.ScalingSchedule]$scheduleObj
}

# Create or update scaling plan
$hostPoolRef = @(@{
    HostPoolArmPath    = "/subscriptions/$($sub.avd_subscription_id)/resourceGroups/$rgName/providers/Microsoft.DesktopVirtualization/hostPools/$hostPoolName"
    ScalingPlanEnabled = $true
})

$existingPlan = Get-AzWvdScalingPlan -ResourceGroupName $rgName -Name $scalingPlanName -ErrorAction SilentlyContinue

if (-not $existingPlan) {
    if ($PSCmdlet.ShouldProcess($scalingPlanName, 'Create AVD scaling plan')) {
        New-AzWvdScalingPlan `
            -ResourceGroupName $rgName `
            -Name $scalingPlanName `
            -Location $sub.location `
            -HostPoolType 'Pooled' `
            -TimeZone $scaling.time_zone `
            -Schedule $schedules `
            -HostPoolReference $hostPoolRef `
            -Tag @{ deployedBy = 'powershell' }
        Write-Host "  Scaling plan created." -ForegroundColor Green
    }
}
else {
    if ($PSCmdlet.ShouldProcess($scalingPlanName, 'Update AVD scaling plan')) {
        Update-AzWvdScalingPlan `
            -ResourceGroupName $rgName `
            -Name $scalingPlanName `
            -Schedule $schedules `
            -HostPoolReference $hostPoolRef
        Write-Host "  Scaling plan updated." -ForegroundColor Green
    }
}

Write-Host "`n=== Scaling Plan Deployment Complete ===" -ForegroundColor Green
