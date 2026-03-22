# ARM Known Deviations (Derived Path)

ARM in this repository is treated as a derived compatibility path.

## Deviations from Bicep Canonical Path

- Bicep wrapper templates are subscription-scope and orchestrate resource-group scoped modules.
- ARM templates are split and manually curated for compatibility; not all Bicep module compositions are represented.
- AVM-native Bicep module consumption is not directly available in ARM JSON.
- Some extension sequencing behavior is easier to express in Bicep modules and orchestration scripts.

## Parity Expectations

- Control plane resources (host pool, app group, workspace, Log Analytics, Key Vault) must be equivalent.
- Session host provisioning and extension chain (domain join, agent install) must be equivalent.
- Diagnostics and RBAC templates are included as separate ARM files:
  - src/arm/diagnostics.json
  - src/arm/identity.json
