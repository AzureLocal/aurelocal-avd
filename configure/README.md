# Configure — Phase 3

Post-deployment configuration for AVD session hosts and supporting infrastructure.

## Tools

| Tool | Directory | Description |
|------|-----------|-------------|
| **Ansible** | [`ansible/`](ansible/) | Playbooks and roles for AVD control plane and session-host config |

## Prerequisites

Complete Phase 1 ([`infrastructure/`](../infrastructure/)) and Phase 2 ([`deploy/`](../deploy/)) first.

## Workflow

```
config/  →  infrastructure/  →  deploy/  →  configure/ (you are here)  →  tests/
```
