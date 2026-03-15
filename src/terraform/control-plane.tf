data "azurerm_client_config" "current" {}

# ── Resource Group ─────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "avd" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

# ── Log Analytics Workspace ───────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "avd" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# ── Key Vault ─────────────────────────────────────────────────────────────────

resource "azurerm_key_vault" "avd" {
  name                            = var.key_vault_name
  location                        = azurerm_resource_group.avd.location
  resource_group_name             = azurerm_resource_group.avd.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = "standard"
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  soft_delete_retention_days      = 7
  tags                            = local.tags
}

# ── AVD Host Pool ─────────────────────────────────────────────────────────────

resource "azurerm_virtual_desktop_host_pool" "avd" {
  name                     = var.host_pool_name
  location                 = azurerm_resource_group.avd.location
  resource_group_name      = azurerm_resource_group.avd.name
  type                     = var.host_pool_type
  load_balancer_type       = var.load_balancer_type
  maximum_sessions_allowed = var.max_session_limit
  start_vm_on_connect      = true
  tags                     = local.tags
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "avd" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.avd.id
  expiration_date = timeadd(timestamp(), "24h")

  lifecycle {
    ignore_changes = [expiration_date]
  }
}

# Store registration token in Key Vault
resource "azurerm_key_vault_secret" "registration_token" {
  name         = "avd-registration-token"
  value        = azurerm_virtual_desktop_host_pool_registration_info.avd.token
  key_vault_id = azurerm_key_vault.avd.id
  tags         = local.tags
}

# ── AVD Application Group ─────────────────────────────────────────────────────

resource "azurerm_virtual_desktop_application_group" "avd" {
  name                = var.app_group_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  type                = "Desktop"
  host_pool_id        = azurerm_virtual_desktop_host_pool.avd.id
  tags                = local.tags
}

# ── AVD Workspace ─────────────────────────────────────────────────────────────

resource "azurerm_virtual_desktop_workspace" "avd" {
  name                = var.workspace_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = local.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avd" {
  workspace_id         = azurerm_virtual_desktop_workspace.avd.id
  application_group_id = azurerm_virtual_desktop_application_group.avd.id
}
