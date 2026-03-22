# Cost Management and Attribution

This guide provides a cost model and operating practices for AVD deployments where control-plane resources run in Azure and session hosts run on Azure Local.

## 1) Cost domains

### Azure control-plane costs
- AVD service-related Azure resources (Log Analytics, Key Vault, optional Storage).
- Monitoring and data ingestion.
- Optional app package storage and backup services.

### Azure Local session-host costs
- Compute and storage consumption on-premises.
- Licensing and operations overhead.
- Network and backup infrastructure costs.

## 2) Tagging strategy for attribution

Apply consistent tags to every Azure resource:
- `service = avd`
- `environment = dev|test|prod`
- `owner = team-name`
- `cost-center = finance-code`
- `workload = control-plane|monitoring|identity|storage`

Use the same logical labels in on-prem cost reporting for reconciliation.

## 3) Log Analytics retention planning

Retention guidance:
- Start with 30 days for operational workspaces.
- Increase only for compliance requirements.
- Route high-volume diagnostics selectively to reduce ingestion overhead.

Key principle: ingest only categories that map to actionable alerts or reporting.

## 4) Cost analysis views

Recommended Azure Cost Management views:
- Cost by resource group (control-plane vs monitoring).
- Cost by tag (`workload`, `environment`, `cost-center`).
- Daily cost trend with anomaly detection.

## 5) KQL samples for cost signals

Ingestion by table:

```kusto
Usage
| where TimeGenerated > ago(30d)
| summarize GB=sum(Quantity) / 1000 by DataType
| order by GB desc
```

Daily ingestion trend:

```kusto
Usage
| where TimeGenerated > ago(30d)
| summarize GB=sum(Quantity) / 1000 by bin(TimeGenerated, 1d)
| order by TimeGenerated asc
```

Per-host heartbeat proxy for active footprint:

```kusto
Heartbeat
| where TimeGenerated > ago(7d)
| summarize ActiveDays=dcount(bin(TimeGenerated, 1d)) by Computer
| order by ActiveDays desc
```

## 6) Optimization playbook
- Tune diagnostic categories and reduce noisy tables.
- Use depth-first pools where user-experience impact is acceptable.
- Right-size session hosts using measured concurrency, not peak speculation.
- Review unattached storage and stale analytics retention monthly.

## 7) Monthly governance checklist
- Validate tag completeness and fix missing tags.
- Compare budget vs actual by environment.
- Review top 10 cost-driving resources.
- Validate autoscale policy effectiveness.
- Capture optimization actions with owners and due dates.

## References
- Azure Cost Management: https://learn.microsoft.com/azure/cost-management-billing/
- Azure Monitor cost planning: https://learn.microsoft.com/azure/azure-monitor/logs/cost-logs
