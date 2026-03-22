# End-to-End Validation Matrix

This matrix defines closure-grade validation requirements for Epic #8.

| Scenario | Bicep | Terraform | PowerShell | ARM | Ansible | Evidence |
|---|---|---|---|---|---|---|
| Config schema positive validation | Required | Required | Required | Required | Required | CI logs + scripts/validate-config.py |
| Config schema negative validation | Required | Required | Required | Required | Required | tests/schemas/invalid-*.yml |
| Control plane deploy | Required | Required | Required | Required | Required | Deployment transcript |
| Session host deploy | Required | Required | Required | Required | Required | Deployment transcript |
| Domain join extension success | Required | Required | Required | Required | Required | Extension provisioning state |
| AVD agent registration | Required | Required | Required | Required | Required | Host pool session host status |
| Diagnostics enabled | Required | Required | Required | Required | Required | Diagnostic settings IDs + KQL results |
| RBAC assignment verification | Required | Required | Required | Required | Required | Role assignment list |
| FSLogix configuration validation | Required | Required | Required | Partial | Required | Registry/path validation evidence |

## Mandatory Artifacts

- Command transcript (or CI logs)
- Validation output
- Negative-path proof (at least one expected failure case)
- Updated docs references in this repository
