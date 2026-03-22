# =============================================================================
# FSLogix Profile Container Configuration — Terraform
# =============================================================================
# Configures FSLogix on session hosts via CustomScriptExtension.
# Supports single and split topologies.
# Note: Backup (Storage Replica / Azure Backup) is a storage-level concern
# handled by the azurelocal-sofs-fslogix companion repo — no session host
# config changes needed. Cloud Cache is an optional add-on, not a topology.
# =============================================================================

variable "fslogix_enabled" {
  description = "Enable FSLogix profile container configuration."
  type        = bool
  default     = false
}

variable "fslogix_share_topology" {
  description = "FSLogix share topology: single or split (three shares — Profiles, ODFC, AppData)."
  type        = string
  default     = "single"
  validation {
    condition     = contains(["single", "split"], var.fslogix_share_topology)
    error_message = "fslogix_share_topology must be 'single' or 'split'."
  }
}

variable "fslogix_single_vhd_path" {
  description = "UNC path for single-share VHDx location."
  type        = string
  default     = ""
}

variable "fslogix_split_profile_path" {
  description = "UNC path for profile VHDx (split topology)."
  type        = string
  default     = ""
}

variable "fslogix_split_office_path" {
  description = "UNC path for Office data container (split topology)."
  type        = string
  default     = ""
}

variable "fslogix_split_appdata_path" {
  description = "UNC path for AppData folder redirection (split topology)."
  type        = string
  default     = ""
}

variable "fslogix_size_in_mb" {
  description = "Max VHDx size per user in MB."
  type        = number
  default     = 30000
}

variable "fslogix_vhd_type" {
  description = "VHD or VHDX."
  type        = string
  default     = "VHDX"
}

variable "fslogix_flip_flop" {
  description = "Use newer flip-flop profile directory naming."
  type        = bool
  default     = false
}

# Build FSLogix configuration script
locals {
  fslogix_base_commands = var.fslogix_enabled ? [
    "New-Item -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Force | Out-Null",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'Enabled' -Value 1 -Type DWord",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'SizeInMBs' -Value ${var.fslogix_size_in_mb} -Type DWord",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VolumeType' -Value '${var.fslogix_vhd_type}' -Type String",
    "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'FlipFlopProfileDirectoryName' -Value ${var.fslogix_flip_flop ? 1 : 0} -Type DWord",
  ] : []

  fslogix_topology_commands = var.fslogix_enabled ? (
    var.fslogix_share_topology == "single" ? [
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VHDLocations' -Value '${var.fslogix_single_vhd_path}' -Type MultiString",
    ] : [
      # Split topology — three shares: Profiles (VHDx), ODFC (VHDx), AppData (Folder Redirection)
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\FSLogix\\Profiles' -Name 'VHDLocations' -Value '${var.fslogix_split_profile_path}' -Type MultiString",
      "New-Item -Path 'HKLM:\\SOFTWARE\\Policies\\FSLogix\\ODFC' -Force | Out-Null",
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\FSLogix\\ODFC' -Name 'Enabled' -Value 1 -Type DWord",
      "Set-ItemProperty -Path 'HKLM:\\SOFTWARE\\Policies\\FSLogix\\ODFC' -Name 'VHDLocations' -Value '${var.fslogix_split_office_path}' -Type MultiString",
      # AppData is handled via Folder Redirection GPO pointing to fslogix_split_appdata_path.
      # The GPO redirects %APPDATA% to \\SOFS\AppData\%USERNAME% — no registry key needed here.
    ]
  ) : []

  fslogix_script = join("; ", concat(local.fslogix_base_commands, local.fslogix_topology_commands))
}

# Deploy FSLogix configuration to each session host
resource "azapi_resource" "fslogix_ext" {
  for_each = var.fslogix_enabled ? toset(local.vm_names) : toset([])

  type      = "Microsoft.HybridCompute/machines/extensions@2023-10-03-preview"
  name      = "FSLogixConfig"
  location  = var.location
  parent_id = azapi_resource.machine[each.key].id

  body = jsonencode({
    properties = {
      publisher               = "Microsoft.Compute"
      type                    = "CustomScriptExtension"
      typeHandlerVersion      = "1.10"
      autoUpgradeMinorVersion = true
      settings                = {}
      protectedSettings = {
        commandToExecute = "powershell -ExecutionPolicy Bypass -Command \"${local.fslogix_script}\""
      }
    }
  })

  depends_on = [azapi_resource.avd_agent_ext]
}
