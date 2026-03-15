variable "resource_group_name" {
  description = "Resource group for session-host resources."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

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

variable "key_vault_id" {
  description = "Resource ID of the Key Vault containing 'avd-registration-token' and 'domain-join-password'."
  type        = string
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

variable "environment_tag" {
  description = "Environment tag value."
  type        = string
  default     = "production"
}

variable "owner_tag" {
  description = "Owner tag value."
  type        = string
  default     = "platform-team"
}
