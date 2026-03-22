# =============================================================================
# Monitoring & Diagnostics — Terraform
# =============================================================================
# Configures diagnostic settings on AVD resources and optional Defender plan.
# =============================================================================

variable "monitoring_enabled" {
  description = "Enable AVD monitoring and diagnostics."
  type        = bool
  default     = true
}

variable "diagnostics_log_categories" {
  description = "Log categories to enable on the host pool."
  type        = list(string)
  default = [
    "Checkpoint",
    "Error",
    "Management",
    "Connection",
    "HostRegistration",
    "AgentHealthStatus"
  ]
}

variable "defender_enabled" {
  description = "Enable Microsoft Defender for Cloud on session hosts."
  type        = bool
  default     = false
}

variable "alert_rules_enabled" {
  description = "Enable AVD alert rules."
  type        = bool
  default     = false
}

variable "alert_action_group_id" {
  description = "Resource ID of the action group for alert notifications."
  type        = string
  default     = ""
}

# ── Diagnostic settings for Host Pool ─────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "host_pool" {
  count = var.monitoring_enabled ? 1 : 0

  name                       = "${var.host_pool_name}-diag"
  target_resource_id         = azurerm_virtual_desktop_host_pool.avd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd.id

  dynamic "enabled_log" {
    for_each = var.diagnostics_log_categories
    content {
      category = enabled_log.value
    }
  }
}

# ── Diagnostic settings for Workspace ─────────────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "workspace" {
  count = var.monitoring_enabled ? 1 : 0

  name                       = "${var.workspace_name}-diag"
  target_resource_id         = azurerm_virtual_desktop_workspace.avd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd.id

  enabled_log {
    category = "Feed"
  }
}

# ── Diagnostic settings for Application Group ─────────────────────────────────

resource "azurerm_monitor_diagnostic_setting" "app_group" {
  count = var.monitoring_enabled ? 1 : 0

  name                       = "${var.app_group_name}-diag"
  target_resource_id         = azurerm_virtual_desktop_application_group.avd.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.avd.id

  enabled_log {
    category = "Checkpoint"
  }

  enabled_log {
    category = "Error"
  }

  enabled_log {
    category = "Management"
  }
}

# ── Alert: No Available Session Hosts ─────────────────────────────────────────

resource "azurerm_monitor_metric_alert" "no_available_hosts" {
  count = var.alert_rules_enabled ? 1 : 0

  name                = "${var.host_pool_name}-no-available-hosts"
  resource_group_name = azurerm_resource_group.avd.name
  scopes              = [azurerm_virtual_desktop_host_pool.avd.id]
  description         = "Alert when no session hosts are available."
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DesktopVirtualization/hostpools"
    metric_name      = "SessionHostHealthCheckSucceededCount"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  dynamic "action" {
    for_each = var.alert_action_group_id != "" ? [1] : []
    content {
      action_group_id = var.alert_action_group_id
    }
  }

  tags = local.tags
}

# ── Defender for Servers (session hosts) ──────────────────────────────────────

resource "azurerm_security_center_subscription_pricing" "defender_servers" {
  count = var.defender_enabled ? 1 : 0

  tier          = "Standard"
  resource_type = "VirtualMachines"
}
