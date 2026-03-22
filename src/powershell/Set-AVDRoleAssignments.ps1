#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$Scope,

    [Parameter(Mandatory = $false)]
    [string]$DesktopVirtualizationUserGroupId,

    [Parameter(Mandatory = $false)]
    [string]$VmUserLoginGroupId,

    [Parameter(Mandatory = $false)]
    [string]$VmAdminLoginGroupId,

    [Parameter(Mandatory = $false)]
    [string]$StartVmOnConnectPrincipalId
)

$assignments = @(
    @{ PrincipalId = $DesktopVirtualizationUserGroupId; Role = 'Desktop Virtualization User' },
    @{ PrincipalId = $VmUserLoginGroupId; Role = 'Virtual Machine User Login' },
    @{ PrincipalId = $VmAdminLoginGroupId; Role = 'Virtual Machine Administrator Login' },
    @{ PrincipalId = $StartVmOnConnectPrincipalId; Role = 'Desktop Virtualization Power On Contributor' }
)

foreach ($assignment in $assignments) {
    if ([string]::IsNullOrWhiteSpace($assignment.PrincipalId)) {
        continue
    }

    if ($PSCmdlet.ShouldProcess($assignment.PrincipalId, "Assign role '$($assignment.Role)' at scope '$Scope'")) {
        $existing = Get-AzRoleAssignment -ObjectId $assignment.PrincipalId -RoleDefinitionName $assignment.Role -Scope $Scope -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-AzRoleAssignment -ObjectId $assignment.PrincipalId -RoleDefinitionName $assignment.Role -Scope $Scope | Out-Null
            Write-Host "Assigned $($assignment.Role) to $($assignment.PrincipalId)" -ForegroundColor Green
        }
        else {
            Write-Host "Role already assigned: $($assignment.Role) for $($assignment.PrincipalId)" -ForegroundColor DarkYellow
        }
    }
}
