# Scaling Plans

AVD scaling plans automatically manage session host availability based on time-of-day schedules, reducing costs during off-peak hours.

!!! note
    Scaling plans are only supported for **Pooled** host pools. Personal host pools use direct assignment and don't support autoscaling.

## Schedule Phases

| Phase | Purpose | Typical Hours |
|-------|---------|---------------|
| Ramp-Up | Gradually power on hosts before peak | 7:00 - 9:00 |
| Peak | All required hosts available | 9:00 - 17:00 |
| Ramp-Down | Gracefully drain and shut down hosts | 17:00 - 19:00 |
| Off-Peak | Minimum hosts running | 19:00 - 7:00 |

## Configuration

```yaml
scaling:
  enabled: true
  time_zone: "Eastern Standard Time"
  schedules:
    - name: weekday-schedule
      days_of_week: [Monday, Tuesday, Wednesday, Thursday, Friday]
      ramp_up:
        start_time: "07:00"
        algorithm: BreadthFirst
        minimum_hosts_pct: 25
        capacity_threshold_pct: 60
      peak:
        start_time: "09:00"
        algorithm: BreadthFirst
      ramp_down:
        start_time: "17:00"
        algorithm: DepthFirst
        minimum_hosts_pct: 10
        capacity_threshold_pct: 90
        force_logoff: false
        wait_time_minutes: 30
        notification_message: "Your session will be logged off in 30 minutes."
      off_peak:
        start_time: "19:00"
        algorithm: DepthFirst
```

## Load Balancing Algorithms

- **BreadthFirst**: Distributes sessions across all available hosts evenly. Better user experience.
- **DepthFirst**: Fills hosts to capacity before using the next one. Better cost optimization.

## Prerequisites

The AVD service principal needs the **Desktop Virtualization Power On/Off Contributor** role on the resource group containing session hosts.

## Deployment

### PowerShell

```powershell
.\src\powershell\Deploy-AVDScaling.ps1 -ConfigPath config/variables.yml
```

### Terraform

```hcl
scaling_enabled   = true
scaling_time_zone = "Eastern Standard Time"
```

### Bicep

Deploy `scaling.bicep` after the control plane:

```bash
az deployment group create \
  --resource-group rg-avd-prod \
  --template-file src/bicep/scaling.bicep \
  --parameters scalingPlanName=hp-pool01-scaling hostPoolId=<id> ...
```

### Ansible

```bash
ansible-playbook src/ansible/playbooks/site.yml -i inventory.yml --tags scaling
```
