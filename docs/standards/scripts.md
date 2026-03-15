# Script Standards

Conventions for all scripts in this repository — PowerShell, Ansible playbooks, and Azure CLI.

---

## PowerShell

### Logging

Every script **must** write logs. Use the standard `Write-Log` function:

```powershell
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $ts   = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$ts] [$Level] $Message"
    $line | Out-File -FilePath $script:logFile -Append -Encoding utf8
    switch ($Level) {
        "PASS"    { Write-Host "[$ts] [PASS] $Message" -ForegroundColor Green }
        "FAIL"    { Write-Host "[$ts] [FAIL] $Message" -ForegroundColor Red }
        "WARN"    { Write-Host "[$ts] [WARN] $Message" -ForegroundColor Yellow }
        "HEADER"  { Write-Host "[$ts] [----] $Message" -ForegroundColor Cyan }
        default   { Write-Host "[$ts] [INFO] $Message" }
    }
}
```

**Log levels:** `INFO`, `PASS`, `FAIL`, `WARN`, `HEADER`, `VERBOSE`, `DEBUG`

**Log file location:** `logs/<task-folder>/<timestamp>_<script-name>.log`

**Format:** `[yyyy-MM-dd HH:mm:ss] [LEVEL] Message`

### Secret Management

- **All secrets** come from Azure Key Vault via `keyvault://` URIs in the config
- Use the `Resolve-KeyVaultRef` function (Az.KeyVault → fallback az CLI)
- **Never** prompt for credentials interactively — fail hard if Key Vault resolution fails
- **Never** put passwords, keys, or tokens in config files, scripts, or logs

### Idempotency

Scripts must be safe to re-run:

- Check if a resource exists before creating it
- Use `-Force` or equivalent where appropriate
- Log "already exists, skipping" rather than failing on duplicates

### Error Handling

- Use `try/catch` for operations that can fail
- Log failures with `"FAIL"` level before throwing or exiting
- Exit with non-zero code on fatal errors
- Provide actionable error messages (what failed, what to do about it)

### Parameters

- All parameters should have sensible defaults from the central config
- Allow parameter overrides for flexibility: `param > config > error`
- Include a `-WhatIf` switch for dry-run mode
- Include a `-LogPath` parameter to override log file location
- Use `[CmdletBinding()]` and proper param blocks with types

### Config Loading

Scripts load `config/variables.yml` as primary, with fallback to legacy paths:

```powershell
$primaryPath = Join-Path $repoRoot "config\variables.yml"
$legacyPath  = Join-Path $repoRoot "solutions\avd\solution-avd.yml"
```

### Naming

- Script files: `Verb-Noun.ps1` (e.g., `Deploy-AVDSessionHosts.ps1`, `Deploy-AVDSessionHosts-ARM.ps1`)
- Functions: `Verb-Noun` (PowerShell approved verbs)
- Variables: `$PascalCase` for parameters, `$camelCase` for local variables

### Header

Every script must include a `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, and `.NOTES` comment block.

### Author Attribution

Use the real LLC name in script `.NOTES` blocks:

```powershell
.NOTES
    Author:  Hybrid Cloud Solutions
    Contact: support@hybridsolutions.cloud
```

For any example domains, users, or resources in scripts, use **Infinite Improbability Corp (IIC)** — never `contoso`. See [Standards overview](index.md#fictional-identity).

---

## Ansible

- Playbooks use YAML with 2-space indentation
- Variable names use `snake_case`
- Roles go in `configure/ansible/roles/`
- Inventory goes in `configure/ansible/inventory/`
- Use `ansible-vault` for any secrets that must be stored locally

---

## Azure CLI

- Scripts use `#!/bin/bash` shebang
- Check `$?` or use `set -euo pipefail`
- Use `--output none` for commands that don't need output
- Parameterize using environment variables from a `.env` file
