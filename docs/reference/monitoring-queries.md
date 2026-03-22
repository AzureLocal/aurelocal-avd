# Monitoring, Diagnostics, and KQL Queries

Use this page to validate observability coverage across AVD control-plane resources and Azure Local session-host workloads.

## 1) Diagnostic categories by resource

| Resource | Recommended categories | Destination |
|---|---|---|
| Host Pool | `Management`, `Error`, `Checkpoint` | Log Analytics |
| Application Group | `Management`, `Error` | Log Analytics |
| Workspace | `Management`, `Error` | Log Analytics |
| Key Vault | `AuditEvent` | Log Analytics |
| Azure Activity | Subscription activity logs | Log Analytics |

## 2) Common Log Analytics tables

| Table | Purpose |
|---|---|
| `WVDConnections` | Session connection and reconnection events |
| `WVDErrors` | Service and agent-side AVD errors |
| `WVDAgentHealthStatus` | Session host agent state and freshness |
| `WVDCheckpoints` | Broker/session workflow checkpoints |
| `Heartbeat` | VM liveness and MMA/AMA heartbeat |
| `AzureDiagnostics` | Unified diagnostics for configured Azure resources |
| `SecurityEvent` | Security events from Windows session hosts |

## 3) Health and availability queries

### Agent health by host pool

```kusto
WVDAgentHealthStatus
| where TimeGenerated > ago(1h)
| summarize LastSeen=max(TimeGenerated), Hosts=dcount(SessionHostName) by HostPoolName
| order by LastSeen asc
```

### Session host heartbeat freshness

```kusto
Heartbeat
| where TimeGenerated > ago(15m)
| summarize LastHeartbeat=max(TimeGenerated) by Computer
| extend MinutesSinceHeartbeat = datetime_diff('minute', now(), LastHeartbeat)
| order by MinutesSinceHeartbeat desc
```

### Error summary by symbol

```kusto
WVDErrors
| where TimeGenerated > ago(24h)
| summarize Errors=count() by CodeSymbolic, ServiceError
| order by Errors desc
```

## 4) User experience queries

### Connection trends (hourly)

```kusto
WVDConnections
| where TimeGenerated > ago(7d)
| summarize Connections=count(), Users=dcount(UserName) by HostPoolName, bin(TimeGenerated, 1h)
| order by TimeGenerated asc
```

### Top reconnect users

```kusto
WVDConnections
| where TimeGenerated > ago(24h)
| summarize Connections=count() by UserName, HostPoolName
| order by Connections desc
| take 25
```

## 5) FSLogix and profile reliability queries

### FSLogix warnings/errors from Windows events

```kusto
Event
| where TimeGenerated > ago(24h)
| where Source == 'frxsvc'
| summarize Events=count() by EventLevelName, Computer
| order by Events desc
```

### Profile attach error trend

```kusto
Event
| where TimeGenerated > ago(7d)
| where Source == 'frxsvc' and EventLevelName in ('Error','Warning')
| summarize Count=count() by bin(TimeGenerated, 1h), Computer
| order by TimeGenerated asc
```

## 6) Cost sampling queries

### Ingestion estimate by table (last 24h)

```kusto
Usage
| where TimeGenerated > ago(24h)
| summarize GB=sum(Quantity) / 1000 by DataType
| order by GB desc
```

### Daily ingestion trend

```kusto
Usage
| where TimeGenerated > ago(30d)
| summarize GB=sum(Quantity) / 1000 by bin(TimeGenerated, 1d)
| order by TimeGenerated asc
```

## 7) Alerting recommendations
- Agent health staleness over 10 minutes.
- Error rate spike over rolling baseline.
- Heartbeat missing for critical session-host groups.
- Log Analytics ingestion anomaly (sharp day-over-day increase).

## 8) Operational run frequency
- Hourly: host heartbeat and active error checks.
- Daily: connection trend and ingestion checks.
- Weekly: host-pool balancing and user-density review.
