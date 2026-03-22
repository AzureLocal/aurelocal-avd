# Phase Ownership Matrix

This matrix declares responsibility boundaries for each deployment phase.

| Phase | Description | Primary owner | Supporting tools |
|---|---|---|---|
| Phase 0 | Config and schema validation | CI + schema | PowerShell, Python validators |
| Phase 1 | Control plane deployment | Bicep | Terraform, ARM, PowerShell, Ansible |
| Phase 2 | Registration token generation and secret management | PowerShell/Bicep orchestrator | ARM, Terraform, Ansible |
| Phase 3 | Session host provisioning on Azure Local | Bicep session template | Terraform, ARM, PowerShell, Ansible |
| Phase 4 | Domain join and agent install | Bicep/PowerShell extensions | ARM, Ansible |
| Phase 5 | Diagnostics and monitoring enablement | Bicep + Terraform | PowerShell, ARM, Ansible |
| Phase 6 | Identity and RBAC assignments | Bicep + Terraform | PowerShell, ARM, Ansible |
| Phase 7 | FSLogix profile configuration | PowerShell/Ansible | Bicep, Terraform, ARM |
| Phase 8 | Validation matrix execution | Tests + CI | All tools |

## Contract Modes

- Strict direct: Bicep orchestrator and schema validation path.
- Derived: Terraform and ARM parameter generation from canonical config.
- Transitional: legacy PowerShell parameters file accepted until full bridge migration.
