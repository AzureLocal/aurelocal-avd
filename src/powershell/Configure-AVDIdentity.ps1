# =============================================================================
# Configure-AVDIdentity.ps1
# =============================================================================
# Configures RBAC role assignments and Entra ID login extension for AVD.
# Supports ad_only, entra_join, and hybrid_join strategies.
# =============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -Path $ConfigPath

$rg = $config.azure.resource_group
$identity = $config.identity
$strategy = $identity.strategy
$hostPoolName = $config.avd.host_pool.name
$appGroupName = $config.avd.app_group.name

Write-Host "Identity strategy: $strategy" -ForegroundColor Cyan

$subId = (Get-AzContext).Subscription.Id
$appGroupScope = "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/applicationGroups/$appGroupName"
$rgScope = "/subscriptions/$subId/resourceGroups/$rg"

# ── Desktop Virtualization User ───────────────────────────────────────────────
# Grants connection permissions on the app group

$userGroupId = $identity.entra_id.avd_users_group_id
if ($userGroupId) {
    if ($PSCmdlet.ShouldProcess($appGroupName, "Assign Desktop Virtualization User to $userGroupId")) {
        $existing = Get-AzRoleAssignment -ObjectId $userGroupId -Scope $appGroupScope -RoleDefinitionName "Desktop Virtualization User" -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-AzRoleAssignment -ObjectId $userGroupId -Scope $appGroupScope -RoleDefinitionName "Desktop Virtualization User"
            Write-Host "Assigned Desktop Virtualization User role" -ForegroundColor Green
        } else {
            Write-Host "Desktop Virtualization User role already assigned" -ForegroundColor Yellow
        }
    }
}

# ── VM Login Roles (Entra-joined or Hybrid-joined only) ──────────────────────

if ($strategy -ne 'ad_only') {
    # Virtual Machine User Login
    if ($userGroupId) {
        if ($PSCmdlet.ShouldProcess($rg, "Assign Virtual Machine User Login to $userGroupId")) {
            $existing = Get-AzRoleAssignment -ObjectId $userGroupId -Scope $rgScope -RoleDefinitionName "Virtual Machine User Login" -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-AzRoleAssignment -ObjectId $userGroupId -Scope $rgScope -RoleDefinitionName "Virtual Machine User Login"
                Write-Host "Assigned Virtual Machine User Login role" -ForegroundColor Green
            } else {
                Write-Host "Virtual Machine User Login role already assigned" -ForegroundColor Yellow
            }
        }
    }

    # Virtual Machine Administrator Login
    $adminGroupId = $identity.entra_id.avd_admins_group_id
    if ($adminGroupId) {
        if ($PSCmdlet.ShouldProcess($rg, "Assign Virtual Machine Administrator Login to $adminGroupId")) {
            $existing = Get-AzRoleAssignment -ObjectId $adminGroupId -Scope $rgScope -RoleDefinitionName "Virtual Machine Administrator Login" -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-AzRoleAssignment -ObjectId $adminGroupId -Scope $rgScope -RoleDefinitionName "Virtual Machine Administrator Login"
                Write-Host "Assigned Virtual Machine Administrator Login role" -ForegroundColor Green
            } else {
                Write-Host "Virtual Machine Administrator Login role already assigned" -ForegroundColor Yellow
            }
        }
    }

    # Deploy AADLoginForWindows extension on session hosts
    $vmPrefix = $config.avd.session_hosts.vm_name_prefix
    $vmCount = $config.avd.session_hosts.vm_count

    for ($i = 1; $i -le $vmCount; $i++) {
        $vmName = '{0}-{1:D2}' -f $vmPrefix, $i
        if ($PSCmdlet.ShouldProcess($vmName, "Deploy AADLoginForWindows extension")) {
            $extSettings = if ($strategy -eq 'hybrid_join') { @{ mdmId = '' } } else { @{} }

            $extBody = @{
                location   = $config.azure.location
                properties = @{
                    publisher               = 'Microsoft.Azure.ActiveDirectory'
                    type                    = 'AADLoginForWindows'
                    typeHandlerVersion      = '2.0'
                    autoUpgradeMinorVersion = $true
                    settings                = $extSettings
                }
            }
            $extUri = "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.HybridCompute/machines/$vmName/extensions/AADLoginForWindows?api-version=2023-10-03-preview"
            Invoke-AzRestMethod -Method PUT -Path $extUri -Payload ($extBody | ConvertTo-Json -Depth 5)
            Write-Host "AADLoginForWindows deployed on: $vmName" -ForegroundColor Green
        }
    }
}

# ── Additional custom RBAC assignments ────────────────────────────────────────

if ($identity.rbac.custom_assignments) {
    foreach ($assignment in $identity.rbac.custom_assignments) {
        if ($PSCmdlet.ShouldProcess($assignment.scope, "Assign $($assignment.role) to $($assignment.principal_id)")) {
            New-AzRoleAssignment -ObjectId $assignment.principal_id -Scope $assignment.scope -RoleDefinitionName $assignment.role
            Write-Host "Custom assignment: $($assignment.role) on $($assignment.scope)" -ForegroundColor Green
        }
    }
}

Write-Host "`nIdentity & RBAC configuration complete." -ForegroundColor Green
