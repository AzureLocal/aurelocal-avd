#Requires -Version 7.0

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "..\..\config\variables.yml",

    [Parameter(Mandatory = $false)]
    [string]$SchemaFile = "..\..\config\schema\variables.schema.json"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $ConfigFile)) {
    throw "Config file not found: $ConfigFile"
}
if (-not (Test-Path $SchemaFile)) {
    throw "Schema file not found: $SchemaFile"
}

if (-not (Get-Command python -ErrorAction SilentlyContinue) -and -not (Get-Command python3 -ErrorAction SilentlyContinue)) {
    throw "Python is required to run schema validation."
}

$pythonExe = if (Get-Command python -ErrorAction SilentlyContinue) { 'python' } else { 'python3' }
$scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) '..\..\scripts\validate-config.py'

& $pythonExe $scriptPath
if ($LASTEXITCODE -ne 0) {
    throw "Schema validation failed."
}

Write-Host "Configuration validation passed." -ForegroundColor Green
