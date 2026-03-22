# RemoteApps (RDApps) Publishing Guide

This guide covers publishing RemoteApps through AVD Application Groups and operating them at scale on Azure Local session-host infrastructure.

## 1) RemoteApp vs Desktop publishing

Use RemoteApp when:
- Users need one or a few business applications.
- You want tighter app-level access control.
- You need lower endpoint resource overhead than full desktop sessions.

Use Desktop when:
- Users require broad shell access and personalized environments.
- App dependencies are difficult to isolate.

## 2) Application Group model

Recommended structure:
- One host pool per workload class.
- Separate Application Groups by department or app criticality.
- One Workspace per business unit or environment boundary.

Naming example:
- `ag-finance-remoteapp-prod`
- `ag-engineering-remoteapp-prod`

## 3) Publish RemoteApps

PowerShell example:

```powershell
# Create RemoteApp application group
New-AzWvdApplicationGroup -ResourceGroupName $rg -Location $location `
	-HostPoolArmPath $hostPoolId -Name 'ag-finance-remoteapp-prod' -ApplicationGroupType 'RemoteApp'

# Publish an application
New-AzWvdApplication -ResourceGroupName $rg -GroupName 'ag-finance-remoteapp-prod' `
	-Name 'NotepadPP' -FilePath 'C:\Program Files\Notepad++\notepad++.exe' `
	-CommandLineSetting 'DoNotAllow'

# Assign group to workspace
Register-AzWvdApplicationGroup -ResourceGroupName $rg -WorkspaceName $workspaceName `
	-ApplicationGroupPath $appGroupId
```

## 4) RBAC for app assignment

Minimum assignment pattern:
- Assign end users to Application Group scope (not subscription scope).
- Keep operator roles separated from security/audit roles.
- Prefer Entra groups over direct user assignment.

## 5) MSIX app attach and FSLogix

Guidance:
- Use MSIX for clean app lifecycle and version rollback.
- Keep user-state in FSLogix profile containers.
- Separate app package storage from profile container shares.

Operational notes:
- Validate package mount latency during sign-in peaks.
- Track package update windows to avoid user session disruption.

## 6) Diagnostics and monitoring

Track:
- Application launch failures by app group.
- Session disconnects correlated with app startup events.
- Per-app user concurrency trends.

Starter KQL (app group trends):

```kusto
WVDConnections
| where TimeGenerated > ago(24h)
| summarize Connections=count(), Users=dcount(UserName) by HostPoolName, bin(TimeGenerated, 1h)
| order by TimeGenerated asc
```

## 7) Scaling patterns for RemoteApps
- Keep app groups small and domain-aligned for clear ownership.
- Split high-demand apps to dedicated host pools when noisy-neighbor effects appear.
- Use depth-first pools for cost-centric workloads and breadth-first where user experience is primary.

## 8) Validation checklist
- RemoteApp appears in user feed.
- Launch succeeds from multiple client types.
- App group assignment respects least privilege.
- Telemetry shows stable launch and session metrics.
