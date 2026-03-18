<#
.SYNOPSIS
    Configures AVD networking — NSG rules and private endpoints.

.DESCRIPTION
    Applies default AVD NSG rules to the session host subnet and optionally
    deploys private endpoints for the AVD feed/gateway.

.PARAMETER ConfigPath
    Path to the central config/variables.yml file.

.EXAMPLE
    .\Configure-AVDNetworking.ps1 -ConfigPath ..\..\config\variables.yml
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

$networking = $config.networking
$sub = $config.subscription
$cp = $config.control_plane
$rgName = $cp.resource_group

Write-Host "=== AVD Networking Configuration ===" -ForegroundColor Cyan

# Apply default AVD NSG rules
if ($networking.nsg.apply_default_avd_rules) {
    Write-Host "`nApplying default AVD NSG rules..." -ForegroundColor Yellow

    $nsgName = "nsg-avd-sessionhosts"
    $nsg = Get-AzNetworkSecurityGroup -ResourceGroupName $config.session_hosts.resource_group -Name $nsgName -ErrorAction SilentlyContinue

    if (-not $nsg) {
        if ($PSCmdlet.ShouldProcess($nsgName, 'Create NSG with AVD rules')) {
            $nsg = New-AzNetworkSecurityGroup `
                -ResourceGroupName $config.session_hosts.resource_group `
                -Location $sub.location `
                -Name $nsgName `
                -Tag @{ deployedBy = 'powershell'; purpose = 'avd-session-hosts' }

            # Allow outbound HTTPS for AVD service connectivity
            $nsg | Add-AzNetworkSecurityRuleConfig `
                -Name "AllowAVDServiceOutbound" `
                -Description "Allow HTTPS outbound to AVD service" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Outbound `
                -Priority 100 `
                -SourceAddressPrefix VirtualNetwork `
                -SourcePortRange '*' `
                -DestinationAddressPrefix 'WindowsVirtualDesktop' `
                -DestinationPortRange 443 | Out-Null

            # Allow outbound to Azure Monitor
            $nsg | Add-AzNetworkSecurityRuleConfig `
                -Name "AllowAzureMonitorOutbound" `
                -Description "Allow HTTPS outbound to Azure Monitor" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Outbound `
                -Priority 110 `
                -SourceAddressPrefix VirtualNetwork `
                -SourcePortRange '*' `
                -DestinationAddressPrefix 'AzureMonitor' `
                -DestinationPortRange 443 | Out-Null

            # Allow outbound to Azure AD for authentication
            $nsg | Add-AzNetworkSecurityRuleConfig `
                -Name "AllowAzureADOutbound" `
                -Description "Allow HTTPS outbound to Azure AD" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Outbound `
                -Priority 120 `
                -SourceAddressPrefix VirtualNetwork `
                -SourcePortRange '*' `
                -DestinationAddressPrefix 'AzureActiveDirectory' `
                -DestinationPortRange 443 | Out-Null

            # Allow KMS activation
            $nsg | Add-AzNetworkSecurityRuleConfig `
                -Name "AllowKMSActivation" `
                -Description "Allow KMS activation for Windows" `
                -Access Allow `
                -Protocol Tcp `
                -Direction Outbound `
                -Priority 130 `
                -SourceAddressPrefix VirtualNetwork `
                -SourcePortRange '*' `
                -DestinationAddressPrefix 'Internet' `
                -DestinationPortRange 1688 | Out-Null

            $nsg | Set-AzNetworkSecurityGroup | Out-Null
            Write-Host "  NSG '$nsgName' created with default AVD rules." -ForegroundColor Green
        }
    }
    else {
        Write-Host "  NSG '$nsgName' already exists — skipping." -ForegroundColor DarkYellow
    }
}

# Deploy private endpoints for AVD feed
if ($networking.private_endpoints.enabled) {
    Write-Host "`nDeploying AVD private endpoints..." -ForegroundColor Yellow

    $subnetId = $networking.private_endpoints.subnet_id
    if (-not $subnetId) {
        Write-Warning "Private endpoints enabled but subnet_id is not configured — skipping."
        return
    }

    $hostPoolId = "/subscriptions/$($sub.avd_subscription_id)/resourceGroups/$rgName/providers/Microsoft.DesktopVirtualization/hostPools/$($cp.host_pool_name)"

    $peName = "pe-$($cp.host_pool_name)-connection"
    $existingPe = Get-AzPrivateEndpoint -Name $peName -ResourceGroupName $rgName -ErrorAction SilentlyContinue

    if (-not $existingPe) {
        if ($PSCmdlet.ShouldProcess($peName, 'Create private endpoint for AVD host pool')) {
            $peConnection = New-AzPrivateLinkServiceConnection `
                -Name "$peName-conn" `
                -PrivateLinkServiceId $hostPoolId `
                -GroupId 'connection'

            New-AzPrivateEndpoint `
                -Name $peName `
                -ResourceGroupName $rgName `
                -Location $sub.location `
                -Subnet (Get-AzVirtualNetworkSubnetConfig -ResourceId $subnetId) `
                -PrivateLinkServiceConnection $peConnection `
                -Tag @{ deployedBy = 'powershell' } | Out-Null

            Write-Host "  Private endpoint '$peName' created." -ForegroundColor Green
        }
    }
    else {
        Write-Host "  Private endpoint '$peName' already exists — skipping." -ForegroundColor DarkYellow
    }
}

Write-Host "`n=== Networking Configuration Complete ===" -ForegroundColor Green
