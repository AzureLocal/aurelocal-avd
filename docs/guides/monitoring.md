# Monitoring & Diagnostics

This guide explains everything that gets deployed for AVD monitoring — every Azure resource, what it does, how the data flows, and how each IaC tool builds it.

## Architecture

![AVD Monitoring Architecture](../assets/diagrams/avd-monitoring.png)

> *Open the [draw.io source](../assets/diagrams/avd-monitoring.drawio) for an editable version.*

---

## What Gets Deployed

When monitoring is enabled, the automation creates these Azure resources:

| Azure Resource | Resource Type (ARM) | Purpose |
|---|---|---|
| Log Analytics Workspace | `Microsoft.OperationalInsights/workspaces` | Central store for all AVD telemetry. Every log, metric, and heartbeat from the entire solution lands here. Retention is configurable (default 30 days). |
| Host Pool Diagnostic Setting | `Microsoft.Insights/diagnosticSettings` | Wires the host pool to LAW. Streams 6 log categories: Checkpoint, Error, Management, Connection, HostRegistration, AgentHealthStatus. |
| Workspace Diagnostic Setting | `Microsoft.Insights/diagnosticSettings` | Wires the AVD workspace to LAW. Streams the **Feed** log category — tracks when users discover/enumerate published apps. |
| App Group Diagnostic Setting | `Microsoft.Insights/diagnosticSettings` | Wires the application group to LAW. Streams 3 log categories: Checkpoint, Error, Management. |
| Alert: No Available Hosts | `Microsoft.Insights/metricAlerts` | Fires when `SessionHostHealthCheckSucceededCount < 1` for 15 minutes. Severity 1 (Error). Means zero healthy session hosts — users cannot connect. |
| Alert: High Session Count | `Microsoft.Insights/metricAlerts` | Fires when active sessions exceed 80% of host pool capacity. Severity 2 (Warning). Signals you're close to running out of user slots. |
| Alert: Connection Failures | `Microsoft.Insights/metricAlerts` | Fires when failed connections exceed 5 within a 15-minute window. Severity 2 (Warning). Indicates RDP gateway or broker issues. |
| AVD Insights Workbook | `Microsoft.Insights/workbooks` | Pre-built Azure Monitor Workbook that visualizes connection quality, session host health, user activity, and error trends. Deployed by the PowerShell script. |

---

## How the Data Flows

### 1. Session Host Telemetry (VM-level)

Each session host VM on Azure Local has two agents collecting data:

- **Azure Monitor Agent (AMA)** — Deployed as a VM extension (`Microsoft.HybridCompute/machines/extensions` of type `AzureMonitorWindowsAgent`). AMA collects:
    - **Performance counters** — CPU (`\Processor(_Total)\% Processor Time`), memory (`\Memory\Available MBytes`), disk I/O (`\LogicalDisk(*)\Disk Reads/sec`), network (`\Network Interface(*)\Bytes Total/sec`). These land in the `Perf` and `InsightsMetrics` LAW tables.
    - **Windows Event Logs** — System, Application, and FSLogix-specific logs (`Microsoft-FSLogix-Apps/Operational`). Land in the `Event` LAW table.

- **AVD Agent** — The RD Agent installed on every session host during provisioning. It sends a heartbeat to the AVD service every 30 seconds. That heartbeat data is what powers the `WVDAgentHealthStatus` table in LAW. The agent also reports whether the host is accepting new sessions (`AllowNewSessions`), its last heartbeat timestamp, and health check results (DomainJoined, DomainTrust, SxSStack, UrlsAccessible, Monitoring, etc.).

### 2. Control Plane Diagnostics (Azure-side)

Three AVD resources in Azure emit diagnostic logs when wired to LAW via diagnostic settings:

**Host Pool** emits 6 log categories:

| Log Category | What It Captures |
|---|---|
| `Connection` | Every user connection attempt — start, success, disconnect, reconnect. Includes `CorrelationId`, `UserName`, `SessionHostName`, `ClientOS`, `ClientVersion`, `GatewayRegion`. This is the most important table for troubleshooting "user can't connect." |
| `Error` | Every AVD error — `CodeSymbolic` (e.g., `ConnectionFailedNoHealthyRdshAvailable`), `Message`, `Source`, `CorrelationId`. Cross-reference with Connection logs to trace failures to specific sessions. |
| `Checkpoint` | Internal AVD service state transitions — host registration events, session state changes, failover events. Low-level but critical for root cause analysis. |
| `Management` | Administrative operations — scaling actions, host pool config changes, app group updates. Audit trail for who changed what. |
| `HostRegistration` | Session host registration/deregistration events. Shows when a VM joins or leaves the host pool, and why (admin action, health check failure, etc.). |
| `AgentHealthStatus` | Periodic health snapshots per session host — is it reachable, is the SxS stack healthy, can it resolve required URLs, is it domain-joined. Powers AVD Insights "Session Host Health" panel. |

**Workspace** emits 1 log category:

| Log Category | What It Captures |
|---|---|
| `Feed` | User feed discovery events — when a user opens the AVD client and enumerates available desktops/apps. Useful for tracking client adoption and troubleshooting "user sees no desktops." |

**Application Group** emits 3 log categories: Checkpoint, Error, Management (same semantics as host pool but scoped to app group operations).

### 3. Where It All Lands — LAW Tables

| LAW Table | Source | Contains |
|---|---|---|
| `WVDConnections` | Host Pool → Connection | Every session lifecycle event. Each row has `State` (Started, Connected, Completed), `CorrelationId`, `UserName`, `SessionHostName`, `ClientSideIPAddress`, `PredictedNetworkQuality`. |
| `WVDErrors` | Host Pool → Error | Every error. Each row has `CodeSymbolic`, `Message`, `Source`, `ServiceError` (bool — was it Microsoft's fault or config). Filter on `ServiceError == false` to find your own issues. |
| `WVDAgentHealthStatus` | Host Pool → AgentHealthStatus | Latest health per session host. Columns: `SessionHostName`, `LastHeartBeat`, `AllowNewSessions`, `Status`, `HealthCheckResult` (JSON with individual check results). |
| `WVDCheckpoints` | Host Pool + App Group → Checkpoint | Internal AVD state transitions. `Name` column has the checkpoint type. Sparse but invaluable for escalations. |
| `Perf` / `InsightsMetrics` | AMA on session hosts | VM performance counters. Standard columns: `ObjectName`, `CounterName`, `InstanceName`, `CounterValue`, `TimeGenerated`. |
| `Event` | AMA on session hosts | Windows Event Log entries. `EventLog`, `EventLevelName`, `RenderedDescription`. |

### 4. Monitoring Consumers

- **AVD Insights Workbook** — The PowerShell script deploys a custom Azure Monitor Workbook (`Microsoft.Insights/workbooks`). It provides tabbed dashboards: Connection Reliability (success rate, round-trip time), Session Host Health (availability heat map), User Activity (concurrent sessions over time), and Error Analysis (top errors by frequency). The workbook runs KQL queries against the LAW tables above.

- **Metric Alert Rules** — Three `Microsoft.Insights/metricAlerts` resources are created (when `alerts.enabled: true`). Each alert evaluates every 5 minutes (`frequency: PT5M`) over a 15-minute window (`windowSize: PT15M`). When triggered, they fire to the configured Action Group (email, webhook, ITSM, etc.). If no action group is configured, alerts are visible in Azure Portal > Alerts but don't notify anyone.

- **Microsoft Defender for Cloud** — When `defender.enabled: true`, Defender for Servers is enabled on the session host VMs. This adds threat detection, vulnerability assessment, and file integrity monitoring. It costs extra (Defender for Servers Plan 2 pricing).

---

## Configuration — Every Field Explained

```yaml
monitoring:
  enabled: true                    # Master switch. false = skip all monitoring deployment.
  log_analytics:
    workspace_name: "law-avd-prod" # Name of the LAW to create or use.
    resource_group: "rg-avd-prod"  # RG for the LAW. Can be different from the AVD RG.
    retention_days: 30             # How long to keep data in LAW. Min 7, max 730. Higher = more cost.
  diagnostics:
    log_categories:                # Which diagnostic log categories to enable on the host pool.
      - Checkpoint                 # Internal state transitions.
      - Error                      # All AVD errors with CodeSymbolic.
      - Management                 # Admin operations audit trail.
      - Connection                 # User connection lifecycle (start → connect → disconnect).
      - HostRegistration           # VM registration/deregistration events.
      - AgentHealthStatus          # Per-host health snapshots.
  defender:
    enabled: false                 # Enable Defender for Servers on session hosts. Extra cost.
  alerts:
    enabled: true                  # Deploy the 3 metric alert rules (no-hosts, high-sessions, conn-failures).
```

---

## What Each IaC Tool Deploys — Resource by Resource

### Terraform (`src/terraform/monitoring.tf`)

| Terraform Resource | Azure Resource Created | What It Does |
|---|---|---|
| `azurerm_monitor_diagnostic_setting.host_pool` | Diagnostic setting on Host Pool | Conditional (`count = var.monitoring_enabled ? 1 : 0`). Uses a `dynamic "enabled_log"` block to loop over `var.diagnostics_log_categories` and enable each one. Targets the LAW via `log_analytics_workspace_id`. |
| `azurerm_monitor_diagnostic_setting.workspace` | Diagnostic setting on Workspace | Enables the `Feed` log category only. Same conditional pattern. |
| `azurerm_monitor_diagnostic_setting.app_group` | Diagnostic setting on App Group | Enables `Checkpoint`, `Error`, `Management` log categories. |
| `azurerm_monitor_metric_alert.no_available_hosts` | Metric alert rule | Conditional (`count = var.alert_rules_enabled ? 1 : 0`). Monitors `SessionHostHealthCheckSucceededCount` metric on `Microsoft.DesktopVirtualization/hostpools` namespace. Fires when average < 1 over 15min. Links to `var.alert_action_group_id` if provided. |
| `azurerm_monitor_metric_alert.high_session_count` | Metric alert rule | Monitors `ActiveSessionCount` > 80% of max capacity. `var.session_host_count * var.max_sessions_per_host * 0.8` is the computed threshold. |
| `azurerm_monitor_metric_alert.connection_failures` | Metric alert rule | Monitors `ConnectionFailedCount` > 5 in 15min. |

**Variables you set in `terraform.tfvars`:**

```hcl
monitoring_enabled         = true
alert_rules_enabled        = true
alert_action_group_id      = "/subscriptions/.../resourceGroups/.../providers/Microsoft.Insights/actionGroups/ag-avd-ops"
diagnostics_log_categories = ["Checkpoint", "Error", "Management", "Connection", "HostRegistration", "AgentHealthStatus"]
defender_enabled           = false
```

### Bicep (`src/bicep/monitoring.bicep`)

Deploys the same resources using native ARM API types:

| Bicep Resource | ARM Type + API Version | What It Does |
|---|---|---|
| `hostPoolDiag` | `Microsoft.Insights/diagnosticSettings@2021-05-01-preview` | Scoped to the existing host pool via `scope: hostPoolResource`. Uses a `for cat in diagnosticsLogCategories` loop to build the log settings array. |
| `workspaceDiag` | `Microsoft.Insights/diagnosticSettings@2021-05-01-preview` | Scoped to workspace. Enables `Feed` category. |
| `appGroupDiag` | `Microsoft.Insights/diagnosticSettings@2021-05-01-preview` | Scoped to app group. Enables `Checkpoint`, `Error`, `Management`. |
| `noAvailableHostsAlert` | `Microsoft.Insights/metricAlerts@2018-03-01` | `criterionType: 'StaticThresholdCriterion'`, metric `SessionHostHealthCheckSucceededCount`, operator `LessThan`, threshold `1`. |
| `highSessionCountAlert` | `Microsoft.Insights/metricAlerts@2018-03-01` | Same pattern — monitors `ActiveSessionCount`. |
| `connectionFailuresAlert` | `Microsoft.Insights/metricAlerts@2018-03-01` | Monitors connection failures. |

**Deploy command:**

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file src/bicep/monitoring.bicep \
  --parameters hostPoolName=hp-pool01 \
               hostPoolId=/subscriptions/.../hostPools/hp-pool01 \
               workspaceId=/subscriptions/.../workspaces/ws-avd-prod \
               appGroupId=/subscriptions/.../applicationGroups/ag-pool01 \
               logAnalyticsWorkspaceId=/subscriptions/.../workspaces/law-avd-prod \
               monitoringEnabled=true \
               alertRulesEnabled=true
```

### ARM JSON (`src/arm/monitoring.json`)

Auto-generated from the Bicep template via `az bicep build`. Contains the exact same resources in ARM JSON format. Use when Bicep CLI is not available.

### PowerShell (`src/powershell/Deploy-AVDMonitoring.ps1`)

The PowerShell script is the most feature-rich — it deploys everything the Terraform/Bicep modules do, plus the **AVD Insights Workbook**:

1. Loads config via `Config-Loader.ps1`
2. Looks up the LAW resource ID via `Get-AzOperationalInsightsWorkspace`
3. Applies diagnostic settings using `Set-AzDiagnosticSetting` for each of the three AVD resources
4. Builds and deploys a custom `Microsoft.Insights/workbooks` resource with tabbed panels for connection reliability, session host health, user activity, and error analysis
5. Creates metric alert rules via `New-AzMetricAlertRuleV2` with the three threshold conditions

### Ansible (`src/ansible/roles/avd-monitoring/tasks/main.yml`)

Uses `azure_rm_resource` to create the same diagnostic settings and alert rules via raw ARM REST calls. Triggered by the `monitoring` tag in the `site.yml` playbook.

```bash
ansible-playbook src/ansible/playbooks/site.yml -i inventory.yml --tags monitoring
```

---

## Key KQL Queries

### Connection Activity — Last 24 Hours

Shows hourly connection volume. Use to spot patterns (peak hours, overnight drops) and validate scaling plan timing.

```kql
WVDConnections
| where TimeGenerated > ago(24h)
| summarize Connections=count() by bin(TimeGenerated, 1h)
| render timechart
```

### Top Errors by Frequency

Identifies the most common AVD errors. `CodeSymbolic` is the machine-readable error code — search Microsoft docs for resolution steps.

```kql
WVDErrors
| where TimeGenerated > ago(24h)
| summarize ErrorCount=count() by CodeSymbolic
| top 10 by ErrorCount desc
```

### Session Host Health — Current State

Snapshot of every session host's current health status. Use to identify hosts that are unavailable or not accepting new sessions.

```kql
WVDAgentHealthStatus
| where TimeGenerated > ago(1h)
| summarize arg_max(TimeGenerated, *) by SessionHostName
| project SessionHostName, LastHeartBeat,
    Status=iff(AllowNewSessions, 'Available', 'Unavailable')
```

### User Session Duration — Last 7 Days

Identifies users with the longest sessions. Helps with capacity planning — long sessions consume host slots.

```kql
WVDConnections
| where TimeGenerated > ago(7d)
| where State == "Completed"
| extend Duration = datetime_diff('minute', TimeGenerated, SessionStartTime)
| summarize AvgDuration=avg(Duration), MaxDuration=max(Duration) by UserName
| top 20 by AvgDuration desc
```

### Failed Connections — Detailed Trace

Joins connection attempts with their error details for full troubleshooting context.

```kql
WVDConnections
| where TimeGenerated > ago(24h)
| where State == "Started"
| join kind=leftouter (
    WVDErrors
    | where TimeGenerated > ago(24h)
) on CorrelationId
| where isnotempty(CodeSymbolic)
| project TimeGenerated, UserName, SessionHostName, CodeSymbolic, Message, ClientOS, ClientVersion
| order by TimeGenerated desc
```

---

## Alert Rules — Detail

| Alert Name | ARM Metric | Namespace | Operator | Threshold | Window | Frequency | Severity | What It Means |
|---|---|---|---|---|---|---|---|---|
| No Available Hosts | `SessionHostHealthCheckSucceededCount` | `Microsoft.DesktopVirtualization/hostpools` | LessThan | 1 | 15 min | 5 min | 1 (Error) | Zero session hosts are passing health checks. No users can connect. **Immediate action required.** |
| High Session Count | `ActiveSessionCount` | `Microsoft.DesktopVirtualization/hostpools` | GreaterThan | 80% of capacity | 15 min | 5 min | 2 (Warning) | Getting close to max user capacity. Consider spinning up more hosts or checking if scaling plan is stuck. |
| Connection Failures | `ConnectionFailedCount` | `Microsoft.DesktopVirtualization/hostpools` | GreaterThan | 5 | 15 min | 5 min | 2 (Warning) | Multiple users failing to connect. Could be broker issue, network issue, or all hosts are at capacity. |

---

## Troubleshooting

| Symptom | What to Check | KQL |
|---|---|---|
| No data in LAW | Verify diagnostic settings exist on all 3 AVD resources. Check AMA extension is installed on session hosts. | `WVDConnections \| take 1` — if empty, diag settings are broken |
| Alerts not firing | Confirm `alerts.enabled: true` and that an action group is configured. Check alert rule status in Portal > Alerts > Alert Rules. | N/A |
| Session host shows "Unavailable" | Check agent health — look for failed health checks (DomainJoined, UrlsAccessible, SxSStack). | `WVDAgentHealthStatus \| where SessionHostName == "..." \| project HealthCheckResult` |
| High CPU / memory on hosts | Check Perf counters. Also verify FSLogix VHDx isn't oversized or fragmented. | `Perf \| where ObjectName == "Processor" \| where CounterName == "% Processor Time" \| where InstanceName == "_Total" \| summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer` |
