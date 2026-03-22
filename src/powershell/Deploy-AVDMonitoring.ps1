# =============================================================================
# Deploy-AVDMonitoring.ps1
# =============================================================================
# Deploys AVD Insights workbook, diagnostic settings, and optional alert rules.
# Uses the central config/variables.yml for all settings.
# =============================================================================
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

# Import config loader
. "$PSScriptRoot\common\Config-Loader.ps1"
$config = Get-AVDConfig -Path $ConfigPath

$rg = $config.azure.resource_group
$location = $config.azure.location
$monitoring = $config.monitoring
$hostPoolName = $config.avd.host_pool.name
$workspaceName = $config.avd.workspace.name
$appGroupName = $config.avd.app_group.name

if (-not $monitoring.enabled) {
    Write-Host "Monitoring is disabled in config. Skipping." -ForegroundColor Yellow
    return
}

$lawName = $monitoring.log_analytics.workspace_name
$lawRg = $monitoring.log_analytics.resource_group
if (-not $lawRg) { $lawRg = $rg }

# Get LAW resource ID
$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $lawRg -Name $lawName
$lawId = $law.ResourceId
Write-Host "Log Analytics Workspace: $lawId"

# ── Diagnostic Settings ───────────────────────────────────────────────────────

$logCategories = $monitoring.diagnostics.log_categories
if (-not $logCategories) {
    $logCategories = @('Checkpoint', 'Error', 'Management', 'Connection', 'HostRegistration', 'AgentHealthStatus')
}

# Host Pool diagnostics
$hostPool = Get-AzWvdHostPool -ResourceGroupName $rg -Name $hostPoolName
if ($PSCmdlet.ShouldProcess($hostPoolName, "Set diagnostic settings")) {
    $logs = $logCategories | ForEach-Object {
        New-AzDiagnosticSettingLogSettingsObject -Category $_ -Enabled $true
    }
    Set-AzDiagnosticSetting -Name "${hostPoolName}-diag" `
        -ResourceId $hostPool.Id `
        -WorkspaceId $lawId `
        -Log $logs
    Write-Host "Diagnostic settings applied to host pool: $hostPoolName" -ForegroundColor Green
}

# Workspace diagnostics
$workspace = Get-AzWvdWorkspace -ResourceGroupName $rg -Name $workspaceName
if ($PSCmdlet.ShouldProcess($workspaceName, "Set diagnostic settings")) {
    $wsLogs = @(New-AzDiagnosticSettingLogSettingsObject -Category 'Feed' -Enabled $true)
    Set-AzDiagnosticSetting -Name "${workspaceName}-diag" `
        -ResourceId $workspace.Id `
        -WorkspaceId $lawId `
        -Log $wsLogs
    Write-Host "Diagnostic settings applied to workspace: $workspaceName" -ForegroundColor Green
}

# App Group diagnostics
$appGroupRid = "/subscriptions/$((Get-AzContext).Subscription.Id)/resourceGroups/$rg/providers/Microsoft.DesktopVirtualization/applicationGroups/$appGroupName"
if ($PSCmdlet.ShouldProcess($appGroupName, "Set diagnostic settings")) {
    $agLogs = @('Checkpoint', 'Error', 'Management') | ForEach-Object {
        New-AzDiagnosticSettingLogSettingsObject -Category $_ -Enabled $true
    }
    Set-AzDiagnosticSetting -Name "${appGroupName}-diag" `
        -ResourceId $appGroupRid `
        -WorkspaceId $lawId `
        -Log $agLogs
    Write-Host "Diagnostic settings applied to app group: $appGroupName" -ForegroundColor Green
}

# ── AVD Insights Workbook ─────────────────────────────────────────────────────

if ($PSCmdlet.ShouldProcess("AVD Insights Workbook", "Deploy")) {
    $workbookName = "AVD-Insights-${hostPoolName}"
    $workbookId = [guid]::NewGuid().ToString()

    $workbookContent = @{
        version  = "Notebook/1.0"
        items    = @(
            @{
                type  = 1
                content = @{
                    json = "## AVD Insights — $hostPoolName`n`nThis workbook provides monitoring for Azure Virtual Desktop session hosts on Azure Local."
                }
                name = "header"
            }
            @{
                type  = 3
                content = @{
                    version   = "KqlItem/1.0"
                    query     = "WVDConnections | where TimeGenerated > ago(24h) | summarize Connections=count() by bin(TimeGenerated, 1h) | render timechart"
                    size      = 0
                    title     = "Connection Activity (24h)"
                    queryType = 0
                    resourceType = "microsoft.operationalinsights/workspaces"
                }
                name = "connections-chart"
            }
            @{
                type  = 3
                content = @{
                    version   = "KqlItem/1.0"
                    query     = "WVDErrors | where TimeGenerated > ago(24h) | summarize ErrorCount=count() by CodeSymbolic | top 10 by ErrorCount desc"
                    size      = 0
                    title     = "Top Errors (24h)"
                    queryType = 0
                    resourceType = "microsoft.operationalinsights/workspaces"
                }
                name = "errors-table"
            }
            @{
                type  = 3
                content = @{
                    version   = "KqlItem/1.0"
                    query     = "WVDAgentHealthStatus | where TimeGenerated > ago(1h) | summarize arg_max(TimeGenerated, *) by SessionHostName | project SessionHostName, LastHeartBeat, Status=iff(AllowNewSessions, 'Available', 'Unavailable')"
                    size      = 0
                    title     = "Session Host Health"
                    queryType = 0
                    resourceType = "microsoft.operationalinsights/workspaces"
                }
                name = "host-health"
            }
        )
    } | ConvertTo-Json -Depth 10

    $body = @{
        location   = $location
        tags       = @{ hidden_title = $workbookName }
        kind       = "shared"
        properties = @{
            displayName    = $workbookName
            serializedData = $workbookContent
            sourceId       = $lawId
            category       = "Azure Virtual Desktop"
        }
    }

    $subId = (Get-AzContext).Subscription.Id
    $uri = "/subscriptions/$subId/resourceGroups/$rg/providers/Microsoft.Insights/workbooks/${workbookId}?api-version=2022-04-01"
    Invoke-AzRestMethod -Method PUT -Path $uri -Payload ($body | ConvertTo-Json -Depth 10)
    Write-Host "AVD Insights workbook deployed: $workbookName" -ForegroundColor Green
}

# ── Alert Rules ───────────────────────────────────────────────────────────────

if ($monitoring.alerts.enabled) {
    if ($PSCmdlet.ShouldProcess("No Available Hosts Alert", "Create")) {
        $alertName = "${hostPoolName}-no-available-hosts"
        $condition = New-AzMetricAlertRuleV2Criteria `
            -MetricName "SessionHostHealthCheckSucceededCount" `
            -MetricNamespace "Microsoft.DesktopVirtualization/hostpools" `
            -TimeAggregation Average `
            -Operator LessThan `
            -Threshold 1

        $params = @{
            Name              = $alertName
            ResourceGroupName = $rg
            TargetResourceId  = $hostPool.Id
            Condition         = $condition
            WindowSize        = (New-TimeSpan -Minutes 15)
            Frequency         = (New-TimeSpan -Minutes 5)
            Severity          = 1
            Description       = "Alert when no session hosts are available."
        }
        Add-AzMetricAlertRuleV2 @params
        Write-Host "Alert rule created: $alertName" -ForegroundColor Green
    }
}

Write-Host "`nAVD monitoring deployment complete." -ForegroundColor Green
