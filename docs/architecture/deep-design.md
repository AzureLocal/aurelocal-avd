# Architecture Deep Design

This page provides detailed architecture and decision guidance for AVD control-plane resources in Azure and session hosts on Azure Local.

## Control plane: components and responsibilities
- Host Pool: logical grouping of session hosts. Defines `personal` vs `pooled` assignment, load-balancing behavior, and diagnostics scope.
- Application Group: publishes desktops or RemoteApps; ties to role assignments for end-user access.
- Workspace: user-facing aggregator; maps Application Groups to user experience.
- Key Vault: stores secrets used during provisioning (domain join credentials, certificates). Access controlled via Managed Identity or service principal.
- Log Analytics (LAW): central diagnostics ingestion for AVD control-plane categories and session-host telemetry.
- Storage: optional Azure Storage for MSIX app attach or cloud-backed FSLogix scenarios.

Design notes:
- Treat the control plane as subscription-scoped and idempotent; prefer modules (Bicep modules / AVM) and expose outputs used by session-host provisioning (hostPoolId, workspaceId, lawResourceId).
- Use `Key Vault` for secrets; grant least-privilege access via managed identities on deployment principals.

## Session-host topologies
- Single-cluster: one Azure Local cluster hosting all session hosts — simpler management, single point of failure at host level.
- Multi-cluster: multiple Azure Local clusters (regional or fault-domain separation) — requires cross-cluster identity and network planning.
- Distributed SOFS (guest cluster approach): recommended pattern — guest S2D cluster inside VMs provides FSLogix SMB shares with stacked resiliency (host CSV + guest S2D).

## Identity patterns
- AD DS (domain-join): required for Azure Local when using on-premises SMB and Kerberos for FSLogix.
- Hybrid Entra ID: domain-joined + Entra registration; supports SSO and Conditional Access while maintaining Kerberos SMB for profiles.
- Entra-only + Cloud Cache: viable for Entra-only scenarios — requires FSLogix Cloud Cache (CCD) and cloud storage backing; increases complexity for SOFS integration.

Recommendation: default to AD DS / hybrid Entra ID for Azure Local deployments unless the environment is Entra-native and cloud-based profile caching is acceptable.

## Network design
- Egress: session-hosts must reach broker endpoints, Entra ID, Windows Update, and Log Analytics over HTTPS (443).
- SMB: keep FSLogix SMB traffic on the same L2/L3 domain (low latency). Avoid routing SMB across wide-area links.
- DNS: ensure session-hosts resolve both on-prem and Azure endpoints; consider split-horizon DNS for internal names.
- Ports & rules: document minimal required ports (RDP/UDP via AVD gateway handled by Azure; SMB 445 for profiles; WinRM 5985/5986 for automation).

## DR, backups and availability
- Control-plane: maintain ARM/Bicep source of truth; backup Key Vault contents via Key Vault backup and export parameterized templates for faster recovery.
- FSLogix profiles: recommend backups of profile containers or use replication for SOFS (storage-level replication) and regularly test restore procedures.
- Disaster scenarios: document runbooks for control-plane redeploy from IaC, profile restore, and reprovisioning session-hosts from golden images.

## Cost and sizing guidance
- Log Analytics: retention and ingestion drive costs; keep diagnostic categories scoped (only required categories) and use sampling for high-volume telemetry.
- Session-host sizing: provision VMs based on expected concurrency; prefer tested session density per SKU rather than overcommitting CPU; use autoscale to optimize costs.

## Worked deployment patterns

### Small footprint (up to 100 users)
- One pooled host pool.
- Single Azure Local cluster.
- One SOFS share and one Log Analytics workspace.

### Medium footprint (100-500 users)
- Multiple app groups on shared host pools.
- Separate prod/non-prod host pools.
- Dedicated monitoring workspace and defined DR for profile containers.

### Large footprint (500+ users)
- Multi-cluster session-host strategy.
- Segmented host pools by workload tier.
- Replicated profile storage and tested DR runbooks.

## Outputs and contracts
- Ensure the control-plane module exports canonical outputs:
	- `hostPoolResourceId`
	- `applicationGroupResourceId`
	- `workspaceResourceId`
	- `logAnalyticsWorkspaceId`
	- `keyVaultResourceId`

These outputs are consumed by session-host provisioning modules and orchestration scripts.

## Parameter mapping summary

| Functional area | Canonical config | Bicep parameter family | Terraform variable family | PowerShell input |
|---|---|---|---|---|
| Host pool | `host_pool.*` | `hostPool*` | `host_pool_*` | `-HostPool*` |
| Diagnostics | `monitoring.*` | `logAnalytics*`, `diagnostic*` | `log_analytics_*` | `-LogAnalytics*` |
| Identity/RBAC | `identity.*`, `rbac.*` | `principal*`, `roleAssignment*` | `principal_*`, `role_assignment_*` | `-Principal*`, `-Role*` |
| FSLogix | `fslogix.*` | `fslogix*` | `fslogix_*` | `-FSLogix*` |

## References
- Microsoft AVD docs: https://learn.microsoft.com/azure/virtual-desktop/
- FSLogix docs: https://learn.microsoft.com/fslogix/
- Azure Monitor diagnostic settings: https://learn.microsoft.com/azure/azure-monitor/alerts/diagnostic-settings
- Host pool guide: ../reference/host-pool-options.md
- FSLogix guide: ./fslogix-integration.md
- Monitoring guide: ../reference/monitoring-queries.md
- Cost guide: ../operations/cost-management.md
