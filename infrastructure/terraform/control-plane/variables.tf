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
