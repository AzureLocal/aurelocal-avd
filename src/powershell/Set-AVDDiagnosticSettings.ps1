#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceId,

    [Parameter(Mandatory = $true)]
    [string]$WorkspaceId,

    [Parameter(Mandatory = $false)]
    [string]$Name = 'avd-diagnostics',

    [Parameter(Mandatory = $false)]
    [string[]]$Categories = @('Checkpoint', 'Error', 'Management')
)

$logs = @()
foreach ($category in $Categories) {
    $logs += @{ category = $category; enabled = $true }
}

if ($PSCmdlet.ShouldProcess($ResourceId, "Configure diagnostic settings '$Name'")) {
    New-AzDiagnosticSetting -Name $Name -ResourceId $ResourceId -WorkspaceId $WorkspaceId -Log $logs | Out-Null
    Write-Host "Diagnostic settings applied to $ResourceId" -ForegroundColor Green
}
