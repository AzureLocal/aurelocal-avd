# Monitoring Validation Queries

Run these queries in Log Analytics after deployment to validate diagnostics and host readiness.

## Agent Health

```kusto
WVDAgentHealthStatus
| where TimeGenerated > ago(1h)
| summarize LastSeen=max(TimeGenerated), Hosts=dcount(SessionHostName) by HostPoolName
```

## Connection Volume

```kusto
WVDConnections
| where TimeGenerated > ago(24h)
| summarize Connections=count() by UserName, HostPoolName
| order by Connections desc
```

## Error Summary

```kusto
WVDErrors
| where TimeGenerated > ago(24h)
| summarize Errors=count() by CodeSymbolic, ServiceError
| order by Errors desc
```

## Heartbeat

```kusto
Heartbeat
| where TimeGenerated > ago(5m)
| summarize LastHeartbeat=max(TimeGenerated) by Computer
| order by LastHeartbeat desc
```

## Checkpoints

```kusto
WVDCheckpoints
| where TimeGenerated > ago(1h)
| summarize Events=count() by Source, Name
| order by Events desc
```
