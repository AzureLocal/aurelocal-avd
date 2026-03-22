resource "azurerm_monitor_diagnostic_setting" "host_pool" {
  name                       = "diag-hostpool"
  target_resource_id         = azurerm_virtual_desktop_host_pool.avd.id
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
  enabled_log {
    category = "Connection"
  }
  enabled_log {
    category = "HostRegistration"
  }
  enabled_log {
    category = "AgentHealthStatus"
  }
}

resource "azurerm_monitor_diagnostic_setting" "app_group" {
  name                       = "diag-appgroup"
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

resource "azurerm_monitor_diagnostic_setting" "workspace" {
  name                       = "diag-workspace"
  target_resource_id         = azurerm_virtual_desktop_workspace.avd.id
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
  enabled_log {
    category = "Feed"
  }
}
