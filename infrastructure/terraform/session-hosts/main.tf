locals {
  tags = {
    environment = var.environment_tag
    owner       = var.owner_tag
    deployed_by = "terraform"
  }
  vm_names = [for i in range(1, var.vm_count + 1) : format("%s-%02d", var.vm_name_prefix, i)]
}

# ── Retrieve secrets from Key Vault ──────────────────────────────────────────

data "azurerm_key_vault_secret" "registration_token" {
  name         = "avd-registration-token"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "domain_join_password" {
  name         = "domain-join-password"
  key_vault_id = var.key_vault_id
}

# ── Network Interfaces ────────────────────────────────────────────────────────
# Arc-enabled VM NICs use the AzAPI provider for the AzureStackHCI resource type.

resource "azapi_resource" "nic" {
  for_each = toset(local.vm_names)

  type      = "Microsoft.AzureStackHCI/networkInterfaces@2023-09-01-preview"
  name      = "${each.value}-nic"
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = jsonencode({
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    tags = local.tags
    properties = {
      ipConfigurations = [
        {
          name = "ipconfig1"
          properties = {
            subnet = {
              id = "${var.vnet_id}/subnets/${var.subnet_name}"
            }
          }
        }
      ]
    }
  })
}

# ── HybridCompute Machines (Arc VMs) ─────────────────────────────────────────

resource "azapi_resource" "machine" {
  for_each = toset(local.vm_names)

  type      = "Microsoft.HybridCompute/machines@2023-10-03-preview"
  name      = each.value
  location  = var.location
  parent_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"

  body = jsonencode({
    extendedLocation = {
      name = var.custom_location_id
      type = "CustomLocation"
    }
    kind     = "HCI"
    identity = { type = "SystemAssigned" }
    tags     = local.tags
  })

  depends_on = [azapi_resource.nic]
}

# ── Domain Join Extension ─────────────────────────────────────────────────────

resource "azapi_resource" "domain_join_ext" {
  for_each = toset(local.vm_names)

  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "JsonADDomainExtension"
  location  = var.location
  parent_id = azapi_resource.machine[each.key].id

  body = jsonencode({
    properties = {
      publisher            = "Microsoft.Compute"
      type                 = "JsonADDomainExtension"
      typeHandlerVersion   = "1.3"
      autoUpgradeMinorVersion = true
      settings = {
        domainToJoin = var.domain_fqdn
        ouPath       = var.ou_path
        user         = var.domain_join_user
        restart      = "true"
        options      = "3"
      }
      protectedSettings = {
        password = data.azurerm_key_vault_secret.domain_join_password.value
      }
    }
  })

  depends_on = [azapi_resource.machine]
}

# ── AVD Agent Extension ───────────────────────────────────────────────────────

resource "azapi_resource" "avd_agent_ext" {
  for_each = toset(local.vm_names)

  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "AVDAgent"
  location  = var.location
  parent_id = azapi_resource.machine[each.key].id

  body = jsonencode({
    properties = {
      publisher          = "Microsoft.Powershell"
      type               = "DSC"
      typeHandlerVersion = "2.83"
      autoUpgradeMinorVersion = true
      settings = {
        modulesUrl            = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip"
        configurationFunction = "Configuration.ps1\\AddSessionHost"
        properties = {
          registrationInfoToken = data.azurerm_key_vault_secret.registration_token.value
        }
      }
    }
  })

  depends_on = [azapi_resource.domain_join_ext]
}

data "azurerm_client_config" "current" {}
