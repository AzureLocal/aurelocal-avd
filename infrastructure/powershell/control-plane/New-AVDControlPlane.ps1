<#
.SYNOPSIS
    Deploys the Azure Virtual Desktop control plane in Azure.

.DESCRIPTION
    This script:
      1. Creates (or validates) a resource group.
      2. Deploys a Log Analytics Workspace for AVD diagnostics.
      3. Deploys an Azure Key Vault for secrets (registration token, domain-join credentials).
      4. Creates an AVD host pool.
      5. Creates an AVD application group (desktop or RemoteApp).
      6. Creates an AVD workspace and links the application group.
      7. Retrieves and stores the host-pool registration token in Key Vault.

.PARAMETER ParametersFile
    Path to a parameters.ps1 file containing environment-specific values.
    See parameters.example.ps1 for the expected variables.

.PARAMETER ResourceGroupName
    Name of the Azure resource group to deploy into.

.PARAMETER Location
    Azure region (e.g. eastus, westeurope).

.PARAMETER HostPoolName
    Name of the AVD host pool.

.PARAMETER HostPoolType
    Type of host pool: Pooled or Personal. Default: Pooled.

.PARAMETER LoadBalancerType
    Load-balancer algorithm: BreadthFirst or DepthFirst (Pooled only). Default: BreadthFirst.

.PARAMETER MaxSessionLimit
    Maximum concurrent sessions per session host (Pooled only). Default: 10.

.PARAMETER WorkspaceName
    Name of the AVD workspace.

.PARAMETER AppGroupName
    Name of the application group. Default: '<HostPoolName>-DAG' (Desktop Application Group).

.PARAMETER KeyVaultName
    Name of the Azure Key Vault (must be globally unique).

.PARAMETER LogAnalyticsWorkspaceName
    Name of the Log Analytics workspace for AVD diagnostics.

.PARAMETER EnvironmentTag
    Value for the 'environment' resource tag. Default: production.

.PARAMETER OwnerTag
    Value for the 'owner' resource tag. Default: platform-team.

.EXAMPLE
    .\New-AVDControlPlane.ps1 -ParametersFile .\parameters.ps1

.EXAMPLE
    .\New-AVDControlPlane.ps1 `
        -ResourceGroupName "rg-avd-prod" `
        -Location "eastus" `
        -HostPoolName "hp-azurelocal-pool01" `
        -WorkspaceName "ws-avd-prod" `
        -AppGroupName "ag-desktops" `
        -KeyVaultName "kv-avd-prod-001" `
        -LogAnalyticsWorkspaceName "law-avd-prod"

.NOTES
    Requires Az PowerShell module >= 9.0 and Contributor rights on the target subscription.
    Run Connect-AzAccount before executing this script.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ParametersFile,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [string]$Location,

    [Parameter(Mandatory = $false)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Pooled', 'Personal')]
    [string]$HostPoolType = 'Pooled',

    [Parameter(Mandatory = $false)]
    [ValidateSet('BreadthFirst', 'DepthFirst')]
    [string]$LoadBalancerType = 'BreadthFirst',

    [Parameter(Mandatory = $false)]
    [int]$MaxSessionLimit = 10,

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$AppGroupName,

    [Parameter(Mandatory = $false)]
    [string]$KeyVaultName,

    [Parameter(Mandatory = $false)]
    [string]$LogAnalyticsWorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$EnvironmentTag = 'production',

    [Parameter(Mandatory = $false)]
    [string]$OwnerTag = 'platform-team'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Load parameters file
if ($ParametersFile) {
    if (-not (Test-Path $ParametersFile)) {
        throw "Parameters file not found: $ParametersFile"
    }
    . $ParametersFile
}

# CLI parameters override parameters file values
if (-not $ResourceGroupName)           { $ResourceGroupName           = $script:ResourceGroupName }
if (-not $Location)                    { $Location                    = $script:Location }
if (-not $HostPoolName)                { $HostPoolName                = $script:HostPoolName }
if (-not $WorkspaceName)               { $WorkspaceName               = $script:WorkspaceName }
if (-not $AppGroupName)                { $AppGroupName                = $script:AppGroupName }
if (-not $KeyVaultName)                { $KeyVaultName                = $script:KeyVaultName }
if (-not $LogAnalyticsWorkspaceName)   { $LogAnalyticsWorkspaceName   = $script:LogAnalyticsWorkspaceName }
#endregion

#region Validate required parameters
foreach ($param in @('ResourceGroupName', 'Location', 'HostPoolName', 'WorkspaceName', 'KeyVaultName', 'LogAnalyticsWorkspaceName')) {
    if (-not (Get-Variable -Name $param -ValueOnly -ErrorAction SilentlyContinue)) {
        throw "Required parameter '$param' is not set. Use -$param or provide a parameters file."
    }
}

if (-not $AppGroupName) {
    $AppGroupName = "$HostPoolName-DAG"
}
#endregion

$tags = @{ environment = $EnvironmentTag; owner = $OwnerTag; deployedBy = 'powershell' }

Write-Host "=== AVD Control Plane Deployment ===" -ForegroundColor Cyan
Write-Host "  Resource Group : $ResourceGroupName" -ForegroundColor Gray
Write-Host "  Location       : $Location" -ForegroundColor Gray
Write-Host "  Host Pool      : $HostPoolName ($HostPoolType)" -ForegroundColor Gray

#region Resource Group
Write-Host "`nEnsuring resource group '$ResourceGroupName'..." -ForegroundColor Yellow
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    if ($PSCmdlet.ShouldProcess($ResourceGroupName, 'Create resource group')) {
        $rg = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Tag $tags
        Write-Host "  Resource group created." -ForegroundColor Green
    }
}
else {
    Write-Host "  Resource group already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Log Analytics Workspace
Write-Host "`nDeploying Log Analytics Workspace '$LogAnalyticsWorkspaceName'..." -ForegroundColor Yellow
$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $LogAnalyticsWorkspaceName -ErrorAction SilentlyContinue
if (-not $law) {
    if ($PSCmdlet.ShouldProcess($LogAnalyticsWorkspaceName, 'Create Log Analytics Workspace')) {
        $law = New-AzOperationalInsightsWorkspace `
            -ResourceGroupName $ResourceGroupName `
            -Name $LogAnalyticsWorkspaceName `
            -Location $Location `
            -Sku PerGB2018 `
            -RetentionInDays 30 `
            -Tag $tags
        Write-Host "  Log Analytics Workspace created: $($law.ResourceId)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Log Analytics Workspace already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Key Vault
Write-Host "`nDeploying Key Vault '$KeyVaultName'..." -ForegroundColor Yellow
$kv = Get-AzKeyVault -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ErrorAction SilentlyContinue
if (-not $kv) {
    if ($PSCmdlet.ShouldProcess($KeyVaultName, 'Create Key Vault')) {
        $kv = New-AzKeyVault `
            -ResourceGroupName $ResourceGroupName `
            -VaultName $KeyVaultName `
            -Location $Location `
            -Sku Standard `
            -EnabledForTemplateDeployment `
            -Tag $tags
        Write-Host "  Key Vault created: $($kv.ResourceId)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Key Vault already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Host Pool
Write-Host "`nCreating host pool '$HostPoolName'..." -ForegroundColor Yellow
$existingPool = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName -Name $HostPoolName -ErrorAction SilentlyContinue
if (-not $existingPool) {
    if ($PSCmdlet.ShouldProcess($HostPoolName, 'Create AVD host pool')) {
        $poolParams = @{
            ResourceGroupName      = $ResourceGroupName
            Name                   = $HostPoolName
            Location               = $Location
            HostPoolType           = $HostPoolType
            LoadBalancerType       = $LoadBalancerType
            PreferredAppGroupType  = 'Desktop'
            Tag                    = $tags
        }
        if ($HostPoolType -eq 'Pooled') {
            $poolParams['MaxSessionLimit'] = $MaxSessionLimit
        }
        $pool = New-AzWvdHostPool @poolParams
        Write-Host "  Host pool created: $($pool.Id)" -ForegroundColor Green
    }
}
else {
    $pool = $existingPool
    Write-Host "  Host pool already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Application Group
Write-Host "`nCreating application group '$AppGroupName'..." -ForegroundColor Yellow
$existingAG = Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroupName -Name $AppGroupName -ErrorAction SilentlyContinue
if (-not $existingAG) {
    if ($PSCmdlet.ShouldProcess($AppGroupName, 'Create AVD application group')) {
        $ag = New-AzWvdApplicationGroup `
            -ResourceGroupName $ResourceGroupName `
            -Name $AppGroupName `
            -Location $Location `
            -HostPoolArmPath $pool.Id `
            -ApplicationGroupType 'Desktop' `
            -Tag $tags
        Write-Host "  Application group created: $($ag.Id)" -ForegroundColor Green
    }
}
else {
    $ag = $existingAG
    Write-Host "  Application group already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Workspace
Write-Host "`nCreating workspace '$WorkspaceName'..." -ForegroundColor Yellow
$existingWS = Get-AzWvdWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction SilentlyContinue
if (-not $existingWS) {
    if ($PSCmdlet.ShouldProcess($WorkspaceName, 'Create AVD workspace')) {
        $ws = New-AzWvdWorkspace `
            -ResourceGroupName $ResourceGroupName `
            -Name $WorkspaceName `
            -Location $Location `
            -ApplicationGroupReference @($ag.Id) `
            -Tag $tags
        Write-Host "  Workspace created: $($ws.Id)" -ForegroundColor Green
    }
}
else {
    Write-Host "  Workspace already exists – skipping." -ForegroundColor DarkYellow
}
#endregion

#region Registration Token
Write-Host "`nRetrieving host-pool registration token..." -ForegroundColor Yellow
$tokenExpiry = (Get-Date).AddHours(24).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
if ($PSCmdlet.ShouldProcess($HostPoolName, 'Create registration token')) {
    $regInfo = New-AzWvdRegistrationInfo `
        -ResourceGroupName $ResourceGroupName `
        -HostPoolName $HostPoolName `
        -ExpirationTime $tokenExpiry

    # Store token in Key Vault
    $secureToken = ConvertTo-SecureString -String $regInfo.Token -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'avd-registration-token' -SecretValue $secureToken | Out-Null
    Write-Host "  Registration token stored in Key Vault secret 'avd-registration-token'." -ForegroundColor Green
}
#endregion

Write-Host "`n=== AVD Control Plane Deployment Complete ===" -ForegroundColor Green
Write-Host "Host Pool  : $HostPoolName" -ForegroundColor Cyan
Write-Host "Workspace  : $WorkspaceName" -ForegroundColor Cyan
Write-Host "Key Vault  : $KeyVaultName (contains registration token)" -ForegroundColor Cyan
Write-Host "`nNext step: deploy session hosts using New-AVDSessionHosts.ps1" -ForegroundColor Cyan
