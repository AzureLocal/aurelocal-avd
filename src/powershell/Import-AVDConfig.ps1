#Requires -Version 7.0

function Resolve-AVDKeyVaultReference {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Reference
    )

    if ($Reference -notmatch '^keyvault://([^/]+)/([^/]+)$') {
        return $Reference
    }

    $vaultName = $Matches[1]
    $secretName = $Matches[2]

    if (-not (Get-Command Get-AzKeyVaultSecret -ErrorAction SilentlyContinue)) {
        throw "Az.KeyVault module is required to resolve keyvault references."
    }

    return Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -AsPlainText
}

function Import-AVDConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveSecrets
    )

    if (-not (Test-Path -Path $ConfigFile)) {
        throw "Config file not found: $ConfigFile"
    }

    $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Yaml
    if (-not $config) {
        throw "Config file is empty or invalid YAML: $ConfigFile"
    }

    if ($ResolveSecrets) {
        if ($config.session_hosts.vm_admin_password) {
            $config.session_hosts.vm_admin_password = Resolve-AVDKeyVaultReference -Reference $config.session_hosts.vm_admin_password
        }
        if ($config.domain.domain_join_password) {
            $config.domain.domain_join_password = Resolve-AVDKeyVaultReference -Reference $config.domain.domain_join_password
        }
    }

    return $config
}
