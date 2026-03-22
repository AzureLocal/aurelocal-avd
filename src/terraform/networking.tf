# =============================================================================
# Networking — Terraform
# =============================================================================
# NSG rules for AVD session hosts and optional private endpoints.
# =============================================================================

variable "nsg_enabled" {
  description = "Create and configure NSG for session hosts."
  type        = bool
  default     = true
}

variable "nsg_name" {
  description = "Name for the Network Security Group."
  type        = string
  default     = ""
}

variable "private_endpoints_enabled" {
  description = "Enable private endpoints for AVD."
  type        = bool
  default     = false
}

variable "private_endpoint_subnet_id" {
  description = "Subnet resource ID for private endpoints."
  type        = string
  default     = ""
}

variable "private_dns_zone_id" {
  description = "Private DNS zone resource ID (privatelink.wvd.microsoft.com) for host pool and workspace PEs."
  type        = string
  default     = ""
}

variable "private_dns_global_zone_id" {
  description = "Private DNS zone resource ID (privatelink-global.wvd.microsoft.com) for the global feed discovery PE."
  type        = string
  default     = ""
}

variable "global_workspace_id" {
  description = "Resource ID of a dedicated workspace used for the global PE (sub-resource: global). Only one global PE is needed across all AVD deployments."
  type        = string
  default     = ""
}

locals {
  nsg_resource_name = var.nsg_name != "" ? var.nsg_name : "${var.host_pool_name}-nsg"
}

# ── Network Security Group ────────────────────────────────────────────────────

resource "azurerm_network_security_group" "avd" {
  count = var.nsg_enabled ? 1 : 0

  name                = local.nsg_resource_name
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = local.tags

  # AVD Service — outbound to WindowsVirtualDesktop service tag
  security_rule {
    name                       = "Allow-AVD-Service"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "WindowsVirtualDesktop"
  }

  # Azure Monitor — outbound for diagnostics
  security_rule {
    name                       = "Allow-AzureMonitor"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureMonitor"
  }

  # Azure AD — outbound for authentication
  security_rule {
    name                       = "Allow-AzureAD"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureActiveDirectory"
  }

  # KMS Activation — outbound
  security_rule {
    name                       = "Allow-KMS"
    priority                   = 130
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1688"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# ── Private Endpoint for Host Pool ────────────────────────────────────────────

resource "azurerm_private_endpoint" "host_pool" {
  count = var.private_endpoints_enabled ? 1 : 0

  name                = "${var.host_pool_name}-pe"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.host_pool_name}-psc"
    private_connection_resource_id = azurerm_virtual_desktop_host_pool.avd.id
    subresource_names              = ["connection"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

# ── Private Endpoint for Workspace ────────────────────────────────────────────

resource "azurerm_private_endpoint" "workspace" {
  count = var.private_endpoints_enabled ? 1 : 0

  name                = "${var.workspace_name}-pe"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.workspace_name}-psc"
    private_connection_resource_id = azurerm_virtual_desktop_workspace.avd.id
    subresource_names              = ["feed"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != "" ? [1] : []
    content {
      name                 = "default"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}

# ── Private Endpoint for Global Feed Discovery ────────────────────────────────
# Only ONE global PE is needed across all AVD deployments in a tenant.
# Uses a dedicated workspace and the "global" sub-resource.
# DNS zone: privatelink-global.wvd.microsoft.com

resource "azurerm_private_endpoint" "global" {
  count = var.private_endpoints_enabled && var.global_workspace_id != "" ? 1 : 0

  name                = "${var.workspace_name}-global-pe"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = local.tags

  private_service_connection {
    name                           = "${var.workspace_name}-global-psc"
    private_connection_resource_id = var.global_workspace_id
    subresource_names              = ["global"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_global_zone_id != "" ? [1] : []
    content {
      name                 = "global"
      private_dns_zone_ids = [var.private_dns_global_zone_id]
    }
  }
}
