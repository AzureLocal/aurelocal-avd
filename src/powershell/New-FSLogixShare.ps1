# =============================================================================
# New-FSLogixShare.ps1
# =============================================================================
# Provisions Azure Files or SMB file shares for FSLogix profile containers.
# Creates shares, sets NTFS permissions, and configures quotas.
# =============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -Path $ConfigPath

$fslogix = $config.fslogix
if (-not $fslogix.enabled) {
    Write-Host "FSLogix is disabled in config. Skipping." -ForegroundColor Yellow
    return
}

$topology = $fslogix.share_topology
Write-Host "FSLogix topology: $topology" -ForegroundColor Cyan

function New-ProfileShare {
    param(
        [string]$SharePath,
        [string]$ShareName,
        [string]$AvdUsersGroup
    )

    # Parse UNC path
    if ($SharePath -match '^\\\\([^\\]+)\\(.+)$') {
        $server = $Matches[1]
        $shareName = $Matches[2]
    } else {
        Write-Error "Invalid UNC path: $SharePath"
        return
    }

    Write-Host "Configuring share: $SharePath"

    # Test connectivity
    if (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
        Write-Warning "Cannot reach file server: $server. Share may need to be created manually."
        return
    }

    # Create share directory if it doesn't exist (requires admin on file server)
    $sessionOpt = New-PSSessionOption -SkipCACheck -SkipCNCheck
    try {
        $session = New-PSSession -ComputerName $server -SessionOption $sessionOpt -ErrorAction Stop
        Invoke-Command -Session $session -ScriptBlock {
            param($shareName, $avdGroup)
            $sharePath = "D:\Shares\$shareName"
            if (-not (Test-Path $sharePath)) {
                New-Item -ItemType Directory -Path $sharePath -Force | Out-Null
                Write-Host "  Created directory: $sharePath"
            }

            # Check if SMB share exists
            $existing = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-SmbShare -Name $shareName -Path $sharePath -FullAccess "Everyone" | Out-Null
                Write-Host "  Created SMB share: $shareName"
            }

            # Set NTFS permissions
            $acl = Get-Acl $sharePath
            $acl.SetAccessRuleProtection($true, $false)

            # CREATOR OWNER - full control on subfolders/files only
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "CREATOR OWNER", "FullControl", "ContainerInherit,ObjectInherit", "InheritOnly", "Allow")
            $acl.AddAccessRule($rule)

            # Users group - Modify (create folder, no traverse)
            if ($avdGroup) {
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $avdGroup, "Modify", "None", "None", "Allow")
                $acl.AddAccessRule($rule)
            }

            # Administrators - full control
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "BUILTIN\Administrators", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.AddAccessRule($rule)

            Set-Acl $sharePath $acl
            Write-Host "  NTFS permissions configured"
        } -ArgumentList $shareName, $config.identity.entra_id.avd_users_group_name
        Remove-PSSession $session
    } catch {
        Write-Warning "Could not configure share remotely: $_"
        Write-Warning "Ensure the share exists at $SharePath with proper NTFS permissions."
    }
}

switch ($topology) {
    'single' {
        $sharePath = $fslogix.single.vhd_path
        if ($PSCmdlet.ShouldProcess($sharePath, "Configure FSLogix single share")) {
            New-ProfileShare -SharePath $sharePath -ShareName 'Profiles' -AvdUsersGroup $config.identity.entra_id.avd_users_group_name
        }
    }

    'split' {
        $profilePath = $fslogix.split.profile_share
        $officePath = $fslogix.split.office_share
        if ($PSCmdlet.ShouldProcess("$profilePath, $officePath", "Configure FSLogix split shares")) {
            New-ProfileShare -SharePath $profilePath -ShareName 'Profiles' -AvdUsersGroup $config.identity.entra_id.avd_users_group_name
            New-ProfileShare -SharePath $officePath -ShareName 'ODFC' -AvdUsersGroup $config.identity.entra_id.avd_users_group_name
        }
    }

    'cloud_cache' {
        Write-Host "Cloud Cache connections:" -ForegroundColor Cyan
        foreach ($conn in $fslogix.cloud_cache.connections) {
            Write-Host "  $conn"
        }
        Write-Host "Cloud Cache shares must be pre-provisioned. Verify connectivity from session hosts." -ForegroundColor Yellow
    }
}

Write-Host "`nFSLogix share provisioning complete." -ForegroundColor Green
