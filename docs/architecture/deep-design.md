# Architecture — Deep Design

This page will contain a deeper architecture design for Azure Virtual Desktop deployments using Azure Local. Sections to be filled:

- Control plane detailed design (Host Pool, App Group, Workspace, Key Vault, LAW, Storage)
- Session-host topologies (single cluster, multi-cluster, distributed SOFS)
- Identity patterns (AD DS, Hybrid Entra ID, Entra-only + Cloud Cache implications)
- Network design (ports, egress, SMB placement, DNS, latency considerations)
- DR and backup patterns (control-plane recovery, SOFS replication, profile backups)
- Cost attribution and sizing guidance (Log Analytics retention, VM sizing vs concurrency)

TODOs:
- Link to FSLogix integration guide
- Add diagrams and decision flows (draw.io sources under `docs/diagrams/`)
- Populate with worked examples (small/medium/large deployments)
