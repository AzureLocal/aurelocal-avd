# =============================================================================
# Variables — Control Plane
# =============================================================================

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

variable "host_pool_name" {
  description = "Name of the AVD host pool."
  type        = string
}

variable "host_pool_type" {
  description = "Host pool type: Pooled or Personal."
  type        = string
  default     = "Pooled"
  validation {
    condition     = contains(["Pooled", "Personal"], var.host_pool_type)
    error_message = "host_pool_type must be 'Pooled' or 'Personal'."
  }
}

variable "load_balancer_type" {
  description = "Load-balancer algorithm for Pooled host pools."
  type        = string
  default     = "BreadthFirst"
  validation {
    condition     = contains(["BreadthFirst", "DepthFirst"], var.load_balancer_type)
    error_message = "load_balancer_type must be 'BreadthFirst' or 'DepthFirst'."
  }
}

variable "max_session_limit" {
  description = "Maximum concurrent sessions per session host."
  type        = number
  default     = 10
}

variable "app_group_name" {
  description = "Name of the AVD application group."
  type        = string
}

variable "workspace_name" {
  description = "Name of the AVD workspace."
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault (must be globally unique)."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
}

# =============================================================================
# Variables — Session Hosts
# =============================================================================

variable "custom_location_id" {
  description = "Resource ID of the Arc Custom Location for the Azure Local cluster."
  type        = string
}

variable "vm_name_prefix" {
  description = "Prefix for session-host VM names."
  type        = string
  default     = "avd-sh"
}

variable "vm_count" {
  description = "Number of session-host VMs to deploy."
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "Azure Local VM size."
  type        = string
  default     = "Standard_D4s_v3"
}

variable "image_id" {
  description = "Resource ID of the Azure Local gallery image."
  type        = string
}

variable "vnet_id" {
  description = "Resource ID of the Azure Local virtual network."
  type        = string
}

variable "subnet_name" {
  description = "Subnet name within the VNet."
  type        = string
  default     = "default"
}

variable "domain_fqdn" {
  description = "Fully-qualified domain name to join."
  type        = string
}

variable "domain_join_user" {
  description = "UPN of the domain-join service account."
  type        = string
}

variable "ou_path" {
  description = "OU path for computer accounts."
  type        = string
  default     = ""
}

# =============================================================================
# Variables — Tags
# =============================================================================

variable "environment_tag" {
  description = "Value for the 'environment' resource tag."
  type        = string
  default     = "production"
}

variable "owner_tag" {
  description = "Value for the 'owner' resource tag."
  type        = string
  default     = "platform-team"
}
