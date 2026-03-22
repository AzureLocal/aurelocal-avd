# Host Pool Options (Pooled vs Personal)

This reference covers host pool configuration options and parameter mappings.

Topics:
- Pooled host pools: load-balancing types (BreadthFirst, DepthFirst), max session limits, autoscale patterns
- Personal (Assigned) host pools: personal assignment types, reserved desktops, profile considerations
- Start VM On Connect: required SPN/RBAC and workflow
- Autoscale strategies: schedule-based, load-based, hybrid
- Mapping: `config/variables.yml` keys → Bicep params → Terraform vars → PowerShell params

TODOs:
- Add example `variables.yml` snippets for each host-pool type
- Add Bicep/Terraform parameter examples
- Add diagnostics queries for per-pool metrics
