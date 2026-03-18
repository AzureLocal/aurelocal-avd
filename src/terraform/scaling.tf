# =============================================================================
# AVD Scaling Plan — Terraform
# =============================================================================
# Creates a scaling plan for Pooled host pools.
# Personal host pools do not support scaling plans.
# =============================================================================

variable "scaling_enabled" {
  description = "Enable AVD scaling plan."
  type        = bool
  default     = false
}

variable "scaling_time_zone" {
  description = "Time zone for scaling schedules."
  type        = string
  default     = "Eastern Standard Time"
}

variable "scaling_schedules" {
  description = "List of scaling schedule configurations."
  type = list(object({
    name                                 = string
    days_of_week                         = list(string)
    ramp_up_start_time                   = string
    ramp_up_load_balancing_algorithm     = string
    ramp_up_minimum_hosts_percent        = number
    ramp_up_capacity_threshold_percent   = number
    peak_start_time                      = string
    peak_load_balancing_algorithm        = string
    ramp_down_start_time                 = string
    ramp_down_load_balancing_algorithm   = string
    ramp_down_minimum_hosts_percent      = number
    ramp_down_capacity_threshold_percent = number
    ramp_down_force_logoff_users         = bool
    ramp_down_wait_time_minutes          = number
    ramp_down_notification_message       = string
    off_peak_start_time                  = string
    off_peak_load_balancing_algorithm    = string
  }))
  default = [{
    name                                 = "weekday-schedule"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "07:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 25
    ramp_up_capacity_threshold_percent   = 60
    peak_start_time                      = "09:00"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "17:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 10
    ramp_down_capacity_threshold_percent = 90
    ramp_down_force_logoff_users         = false
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "Your session will be logged off in 30 minutes."
    off_peak_start_time                  = "19:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }]
}

resource "azurerm_virtual_desktop_scaling_plan" "avd" {
  count = var.scaling_enabled && var.host_pool_type == "Pooled" ? 1 : 0

  name                = "${var.host_pool_name}-scaling"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  time_zone           = var.scaling_time_zone
  tags                = local.tags

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.avd.id
    scaling_plan_enabled = true
  }

  dynamic "schedule" {
    for_each = var.scaling_schedules
    content {
      name                                 = schedule.value.name
      days_of_week                         = schedule.value.days_of_week
      ramp_up_start_time                   = schedule.value.ramp_up_start_time
      ramp_up_load_balancing_algorithm     = schedule.value.ramp_up_load_balancing_algorithm
      ramp_up_minimum_hosts_percent        = schedule.value.ramp_up_minimum_hosts_percent
      ramp_up_capacity_threshold_percent   = schedule.value.ramp_up_capacity_threshold_percent
      peak_start_time                      = schedule.value.peak_start_time
      peak_load_balancing_algorithm        = schedule.value.peak_load_balancing_algorithm
      ramp_down_start_time                 = schedule.value.ramp_down_start_time
      ramp_down_load_balancing_algorithm   = schedule.value.ramp_down_load_balancing_algorithm
      ramp_down_minimum_hosts_percent      = schedule.value.ramp_down_minimum_hosts_percent
      ramp_down_capacity_threshold_percent = schedule.value.ramp_down_capacity_threshold_percent
      ramp_down_force_logoff_users         = schedule.value.ramp_down_force_logoff_users
      ramp_down_wait_time_minutes          = schedule.value.ramp_down_wait_time_minutes
      ramp_down_notification_message       = schedule.value.ramp_down_notification_message
      off_peak_start_time                  = schedule.value.off_peak_start_time
      off_peak_load_balancing_algorithm    = schedule.value.off_peak_load_balancing_algorithm
    }
  }
}
