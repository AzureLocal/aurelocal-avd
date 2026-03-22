// =============================================================================
// AVD Scaling Plan — Bicep
// =============================================================================
// Creates a scaling plan for Pooled host pools with configurable schedules.
// =============================================================================

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------

@description('Name for the scaling plan')
param scalingPlanName string

@description('Azure region')
param location string

@description('Resource ID of the host pool to attach')
param hostPoolId string

@description('Host pool type — scaling only applies to Pooled')
@allowed(['Pooled', 'Personal'])
param hostPoolType string = 'Pooled'

@description('Enable scaling plan')
param scalingEnabled bool = false

@description('Time zone for scaling schedules')
param timeZone string = 'Eastern Standard Time'

@description('Resource tags')
param tags object = {}

// ---------------------------------------------------------------------------
// Schedule Configuration
// ---------------------------------------------------------------------------

@description('Schedule name')
param scheduleName string = 'weekday-schedule'

@description('Days of week for the schedule')
param scheduleDays array = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']

@description('Ramp-up start time (hour)')
param rampUpStartHour int = 7

@description('Ramp-up start time (minute)')
param rampUpStartMinute int = 0

@description('Ramp-up load balancing algorithm')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampUpLBAlgorithm string = 'BreadthFirst'

@description('Ramp-up minimum hosts percent')
param rampUpMinHostsPct int = 25

@description('Ramp-up capacity threshold percent')
param rampUpCapacityPct int = 60

@description('Peak start time (hour)')
param peakStartHour int = 9

@description('Peak start time (minute)')
param peakStartMinute int = 0

@description('Peak load balancing algorithm')
@allowed(['BreadthFirst', 'DepthFirst'])
param peakLBAlgorithm string = 'BreadthFirst'

@description('Ramp-down start time (hour)')
param rampDownStartHour int = 17

@description('Ramp-down start time (minute)')
param rampDownStartMinute int = 0

@description('Ramp-down load balancing algorithm')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampDownLBAlgorithm string = 'DepthFirst'

@description('Ramp-down minimum hosts percent')
param rampDownMinHostsPct int = 10

@description('Ramp-down capacity threshold percent')
param rampDownCapacityPct int = 90

@description('Force logoff users during ramp-down')
param rampDownForceLogoff bool = false

@description('Wait time before force logoff (minutes)')
param rampDownWaitMinutes int = 30

@description('Notification message before forced logoff')
param rampDownNotification string = 'Your session will be logged off in 30 minutes.'

@description('Off-peak start time (hour)')
param offPeakStartHour int = 19

@description('Off-peak start time (minute)')
param offPeakStartMinute int = 0

@description('Off-peak load balancing algorithm')
@allowed(['BreadthFirst', 'DepthFirst'])
param offPeakLBAlgorithm string = 'DepthFirst'

// ---------------------------------------------------------------------------
// Resource
// ---------------------------------------------------------------------------

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2024-04-03' = if (scalingEnabled && hostPoolType == 'Pooled') {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    timeZone: timeZone
    friendlyName: '${scalingPlanName} Scaling Plan'
    hostPoolType: 'Pooled'
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolId
        scalingPlanEnabled: true
      }
    ]
    schedules: [
      {
        name: scheduleName
        daysOfWeek: scheduleDays
        rampUpStartTime: {
          hour: rampUpStartHour
          minute: rampUpStartMinute
        }
        rampUpLoadBalancingAlgorithm: rampUpLBAlgorithm
        rampUpMinimumHostsPct: rampUpMinHostsPct
        rampUpCapacityThresholdPct: rampUpCapacityPct
        peakStartTime: {
          hour: peakStartHour
          minute: peakStartMinute
        }
        peakLoadBalancingAlgorithm: peakLBAlgorithm
        rampDownStartTime: {
          hour: rampDownStartHour
          minute: rampDownStartMinute
        }
        rampDownLoadBalancingAlgorithm: rampDownLBAlgorithm
        rampDownMinimumHostsPct: rampDownMinHostsPct
        rampDownCapacityThresholdPct: rampDownCapacityPct
        rampDownForceLogoffUsers: rampDownForceLogoff
        rampDownWaitTimeMinutes: rampDownWaitMinutes
        rampDownNotificationMessage: rampDownNotification
        offPeakStartTime: {
          hour: offPeakStartHour
          minute: offPeakStartMinute
        }
        offPeakLoadBalancingAlgorithm: offPeakLBAlgorithm
      }
    ]
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------

output scalingPlanId string = scalingEnabled && hostPoolType == 'Pooled' ? scalingPlan.id : ''
output scalingPlanName string = scalingEnabled && hostPoolType == 'Pooled' ? scalingPlan.name : ''
