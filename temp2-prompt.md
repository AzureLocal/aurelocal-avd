# Epic #8 — AVD Full Automation Build-Out (azurelocal-avd)

## Context

You are working in the `e:\git\azurelocal-avd` repository (GitHub: `AzureLocal/azurelocal-avd`).
This repo provides Infrastructure-as-Code for deploying **Azure Virtual Desktop (AVD)** with session hosts on **Azure Local** (formerly Azure Stack HCI).

**Architecture:**
- **Control Plane** (Azure): Host Pool, Application Group, Workspace, Key Vault, Log Analytics
- **Session Hosts** (on-premises Azure Local): Arc-enabled VMs with domain join + AVD agent + FSLogix

**5 IaC tools**: Bicep (canonical), Terraform, PowerShell, ARM, Ansible
**Central config**: `config/variables.example.yml` with JSON Schema at `config/schema/variables.schema.json`

## Your Task

Fully implement **Epic #8** and all 12 child issues listed below. Use `temp2.md` in the repo root as your audit/guidance document — it contains a deep scan of every gap, the evidence matrix, compliance snapshot, and the child issue rewrite map with specific requirements per issue.

**Read these files first** before writing any code:
1. `temp2.md` — the full audit and re-baseline document (YOUR PRIMARY GUIDE)
2. `docs/architecture.md` — the deployment architecture diagram and component table
3. `config/variables.example.yml` — current canonical config
4. `config/schema/variables.schema.json` — current JSON Schema
5. All source files in `src/bicep/`, `src/terraform/`, `src/powershell/`, `src/arm/`, `src/ansible/`
6. All pipeline examples in `examples/pipelines/`
7. All docs in `docs/` (especially `docs/guides/avd-deployment-guide.md`, `docs/standards/automation.md`, `docs/reference/variables.md`)

## Child Issues (in execution order)

### Phase 1: Foundation

**#10 — Config & Schema Expansion**
- Expand `config/variables.example.yml` with new sections: `monitoring` (LAW name, RG, retention, diagnostic categories), `rbac` (role definitions, user/admin group object IDs, service principal for Start VM on Connect), `fslogix` (profile_container_type, share_path, vhd_size_gb, cloud_cache_enabled, exclusions), `image` (source, version)
- Rewrite `config/schema/variables.schema.json` with: `if/then` conditional rules (Pooled → require load_balancer_type + max_session_limit; Personal → require personal_assignment_type), `pattern` for keyvault:// URIs (`^keyvault://[a-zA-Z0-9-]+/[a-zA-Z0-9-]+$`), `pattern` for ARM resource IDs, UUID format for subscription/tenant IDs, minLength/maxLength for naming fields
- Create `docs/reference/variable-mapping.md` — canonical-to-tool mapping table (variables.yml key → Bicep param → Terraform var → PS param → Ansible var → ARM param)
- Add schema negative test cases (config samples that MUST fail validation)

### Phase 2: Fix Stale Guidance

**#30 — Documentation + Diagrams**
- Fix ALL stale paths in docs (`infrastructure/bicep/...` → `src/bicep/...` everywhere)
- Create `docs/reference/tool-parity-matrix.md` — feature matrix showing what each tool supports (control plane, session hosts, monitoring, RBAC, FSLogix, validation)
- Create `docs/reference/phase-ownership.md` — deployment phase → tool responsibility mapping
- Update `docs/architecture.md` with monitoring, RBAC, and FSLogix components
- Update `docs/guides/avd-deployment-guide.md` to reference canonical config and all new sections
- Fix scope statements — clearly mark implemented vs planned per tool

**#32 — CI/CD Pipelines**
- Fix path references in ALL pipeline examples under `examples/pipelines/` (`infrastructure/bicep/` → `src/bicep/`)
- Fix deployment scope in pipelines — control-plane is subscription-scope, not resource-group
- Add schema validation stage (validate config/variables.yml against schema before deploy)
- Add contract validation job to `.github/workflows/` CI
- Ensure OIDC auth patterns are correct in GitHub Actions examples
- Add Pester test stage to CI pipelines

### Phase 3: Tool Contract Convergence

**#12 — PowerShell Automation Scripts**
- Create `src/powershell/Import-AVDConfig.ps1` — YAML bridge that reads `config/variables.yml`, resolves `keyvault://` URIs via `Get-AzKeyVaultSecret`, returns structured hashtable
- Refactor `New-AVDControlPlane.ps1` and `New-AVDSessionHosts.ps1` to accept `-ConfigFile` (YAML) OR legacy `-ParametersFile` (mark transitional)
- Add `Set-AVDDiagnosticSettings.ps1` — diagnostic settings creation for all AVD resources → LAW
- Add `Set-AVDRoleAssignments.ps1` — RBAC role assignments (Desktop Virtualization User, VM User Login, VM Admin Login, Power On Contributor)
- Add `Set-AVDFSLogixConfig.ps1` — FSLogix registry settings via CSE
- Add `Test-AVDConfig.ps1` — validates YAML config against schema
- Mark `parameters.example.ps1` as transitional with header comments

**#14 — Terraform + Azure Verified Modules**
- Add AVM module references where available (check Terraform Registry for `azurerm` AVM modules for AVD resources). If official AVM modules exist, use them; otherwise use `azurerm` resources with best-practice patterns
- Add `monitoring.tf` — diagnostic settings for host pool, app group, workspace → LAW
- Add `identity.tf` — role assignments (Desktop Virtualization User, VM User Login, VM Admin Login, Power On Contributor)
- Add `fslogix.tf` — FSLogix configuration via VM extension
- Expand `outputs.tf` with full inventory (all resource IDs, registration info, diagnostic workspace ID)
- Add validation blocks in `variables.tf` matching JSON Schema constraints
- Create canonical mapping doc
- Update `terraform.tfvars.example` with all new variables

**#16 — Ansible End-to-End Playbooks**
- Add `roles/avd-validation/` with tasks: AVD agent health, domain join verification, network connectivity, FSLogix mount test, LAW heartbeat
- Add `roles/avd-diagnostics/` — diagnostic settings and AMA extension
- Add `roles/avd-rbac/` — role assignments via `azure.azcollection.azure_rm_roleassignment`
- Add `roles/avd-fslogix/` — FSLogix registry configuration
- Add `rescue` blocks to existing roles for failure handling
- Create `playbooks/load-config.yml` — reads `config/variables.yml` and sets Ansible facts
- Update `site.yml` to include all new roles with validation as final mandatory step

### Phase 4: Parity Confirmation

**#18 — Bicep + Azure Verified Modules**
- Integrate AVM modules from the public Bicep registry (`br/public:avm/res/...`):
  - `desktop-virtualization/host-pool` (latest version)
  - `desktop-virtualization/application-group`
  - `desktop-virtualization/workspace`
  - `key-vault/vault`
  - `operational-insights/workspace`
- Add `diagnostics.bicep` — diagnostic settings for all AVD resources → LAW
- Add `identity.bicep` — RBAC role assignments
- Add `fslogix.bicep` — FSLogix config extension for session hosts
- Update `Deploy-AVDSessionHosts.ps1` orchestrator for new templates
- Update `.bicepparam.example` files with new parameters
- Ensure all API versions are latest GA (AVD 2024-04-03, Azure Local 2025-09-01-preview)

**#21 — ARM Templates (from Bicep)**
- Regenerate `control-plane.json` and `session-hosts.json` from compiled Bicep (`az bicep build`)
- Add `diagnostics.json` — derived from diagnostics.bicep
- Add `identity.json` — derived from identity.bicep
- Update parameter files
- Create known deviations table (where ARM diverges from Bicep due to AVM unavailability)
- Update `Deploy-AVDSessionHosts-ARM.ps1` orchestrator

### Phase 5: Platform Integration

**#24 — Monitoring, Defender & Diagnostics**
- Define diagnostic categories per resource:
  - Host Pool: Checkpoint, Error, Management, Connection, HostRegistration, AgentHealthStatus
  - Application Group: Checkpoint, Error, Management
  - Workspace: Checkpoint, Error, Management, Feed
- Add Azure Monitor Agent (AMA) extension for session hosts
- Add Defender for Servers config
- Create `docs/reference/monitoring-queries.md` with KQL:
  - `WVDAgentHealthStatus | where TimeGenerated > ago(1h)`
  - `WVDConnections | where TimeGenerated > ago(24h) | summarize count() by UserName`
  - `WVDErrors | summarize count() by CodeSymbolic, ServiceError`
  - `Heartbeat | where TimeGenerated > ago(5m) | summarize LastHeartbeat=max(TimeGenerated) by Computer`
  - `WVDCheckpoints | where TimeGenerated > ago(1h) | summarize count() by Source, Name`

**#26 — Identity & RBAC Automation**
- Define and implement least-privilege role matrix across all tools:
  - `Desktop Virtualization User` → user group on app group
  - `Virtual Machine User Login` → user group on session host RG
  - `Virtual Machine Administrator Login` → admin group on session host RG
  - `Desktop Virtualization Power On Contributor` → SPN on session host RG (Start VM on Connect)
  - `Desktop Virtualization Session Host Operator` → SPN
- Add RBAC section to canonical config with group IDs and SPN IDs
- Add validation commands to verify assignments post-deployment

**#28 — Image Management & FSLogix Configuration**
- FSLogix registry settings (under `HKLM:\SOFTWARE\FSLogix\Profiles`):
  - `Enabled` = 1
  - `VHDLocations` = SOFS share path (e.g., `\\sofs-cluster\FSLogixProfiles`)
  - `DeleteLocalProfileWhenVHDShouldApply` = 1
  - `FlipFlopProfileDirectoryName` = 1
  - `SizeInMBs` = configurable (default 30720)
  - `VolumeType` = `VHDX`
  - `ProfileType` = 0 (normal) or 3 (read-write, read-only)
- Cloud Cache config (Entra-only): `CCDLocations` instead of `VHDLocations`
- Profile exclusions: `HKLM:\SOFTWARE\FSLogix\Profiles\ExcludeCommonFolders`
  - Teams cache, Outlook OST, OneDrive cache
- SOFS dependency check: validate SMB share reachable (Test-Path on UNC) before enabling FSLogix
- Image management docs: gallery image selection, custom image requirements, marketplace image references for Azure Local

### Phase 6: Validation

**#34 — End-to-End Validation Matrix**
- Create `tests/Test-AVDDeployment.Tests.ps1` (Pester 5):
  - Config schema validation tests (positive + negative)
  - Contract parity tests (all tools read same config keys)
  - Control plane resource assertions (host pool exists, correct type, correct properties)
  - Session host health assertions (AVD agent registered, domain joined, extensions installed)
  - FSLogix mount tests (profile container created on first login)
  - RBAC assignment tests (correct roles on correct scopes)
  - Diagnostic settings tests (categories enabled, LAW receiving data)
- Create `tests/VALIDATION-MATRIX.md` — scenario matrix with per-tool pass/fail columns
- Create `tests/schemas/` — test fixture configs (valid + invalid samples for schema testing)
- Wire tests into CI workflow (`.github/workflows/validate-automation.yml`)

## Technical Requirements

### Azure Verified Modules (AVM)
- **Bicep**: Use `br/public:avm/res/...` modules from the public registry. Check https://azure.github.io/Azure-Verified-Modules/ for latest versions.
- **Terraform**: Use AVM modules from Terraform Registry where available (`Azure/avm-res-desktopvirtualization-hostpool/azurerm`, etc.). Fall back to direct `azurerm`/`azapi` resources where AVM doesn't exist yet.
- **ARM**: Generated from Bicep compilation. AVM is not directly available in ARM — use compiled output.

### API Versions
- AVD: `2024-04-03` (latest GA)
- Azure Local VMs: `2025-09-01-preview`
- Key Vault: `2023-07-01`
- Log Analytics: `2023-09-01`
- Diagnostic Settings: `2021-05-01-preview`
- Role Assignments: `2022-04-01`
- Arc Machines: `2023-06-20-preview`
- Network Interfaces (Azure Local): `2025-09-01-preview`

### Best Practices
- **Bicep**: Use `@description()` decorators, parameter files (`.bicepparam`), `targetScope` declarations, type-safe params, `@minLength()`/`@maxLength()` decorators
- **Terraform**: Use `validation {}` blocks, `locals` for computed values, `lifecycle` blocks, comprehensive `output` blocks, `azapi` for Azure Local resources
- **PowerShell**: Use `[CmdletBinding()]`, `-WhatIf`/`-Confirm` support, `#Requires` statements, approved verbs, structured error handling with `try/catch`, `Write-Verbose` for operational logging
- **Ansible**: Use `azure.azcollection` collection (latest), `rescue` blocks for error handling, `assert` modules for validation, `register` for idempotency checks, `delegate_to: localhost` for Azure API calls
- **ARM**: Use `condition` properties, proper `dependsOn` chains, nested deployments for scope boundaries, `[if()]` functions for conditional resources

### Config Contract
- ALL tools must read from or map to `config/variables.yml`
- Secrets use `keyvault://` URIs — resolved at deploy time by each tool's orchestrator
- Each tool may have a bridge/loader that translates canonical YAML to tool-native format
- The JSON schema is the single enforcement point — CI validates before any deployment
- Bridge modes: **strict direct** (reads YAML), **derived** (generated from YAML), **transitional** (tool-native accepted temporarily)

### Resource Naming (IIC Fictional Company)
```
Resource Group (CP):   rg-iic-avd-hp-eus-01
Resource Group (SH):   rg-iic-avd-sh-eus-01
Key Vault:             kv-iic-platform
Log Analytics:         law-iic-monitor-01
Host Pool:             hp-iic-avd-pool01
App Group:             vdag-iic-avd-eus-01
Workspace:             vdws-iic-avd-eus-01
Session Host VMs:      vm-iicavd-001, vm-iicavd-002, ...
```

## Git Workflow

1. Create feature branch: `git checkout -b feature/epic-8-completion`
2. Implement all changes in the execution order above
3. Commit with conventional commit message referencing all child issues:
   ```
   feat(epic-8): complete AVD full automation build-out

   Closes #10, #12, #14, #16, #18, #21, #24, #26, #28, #30, #32, #34
   ```
4. Push and create PR targeting `main`

## What NOT to Do
- Do not delete or break existing working functionality
- Do not hardcode secrets or credentials anywhere
- Do not use deprecated API versions when newer GA versions exist
- Do not create new tools or languages beyond the 5 already in the repo
- Do not add external dependencies without justification
- Do not close any issue without meeting the Hard Close Gate defined in Epic #8 (contract evidence, parity evidence, repro evidence, dependency evidence)
