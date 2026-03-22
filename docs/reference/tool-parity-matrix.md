# Tool Parity Matrix

This matrix documents current implementation parity for Epic #8 execution and closure validation.

| Capability | Bicep | Terraform | PowerShell | ARM | Ansible |
|---|---|---|---|---|---|
| Canonical config input support | Yes (direct) | Partial (derived) | Partial (transitional + direct) | Partial (derived) | Partial (derived) |
| Control plane deployment | Yes | Yes | Yes | Yes | Yes |
| Session host deployment | Yes | Yes | Yes | Yes | Yes |
| Monitoring diagnostic settings | Yes | Yes | Yes | Yes | Yes |
| Identity and RBAC role assignments | Yes | Yes | Yes | Yes | Yes |
| FSLogix configuration | Yes (extension/script) | Yes (extension/script) | Yes | Partial (script) | Yes |
| Validation and schema checks | Yes | Yes | Yes | Yes | Yes |
| CI what-if / plan support | Yes | Yes | Yes | Yes | Yes |

## Notes

- Canonical source of truth is config/variables.yml.
- Bicep is the strongest direct implementation path.
- ARM templates are a derived path from Bicep where practical.
- Transitional support for src/powershell/parameters.example.ps1 is intentionally retained to avoid breaking existing automation.
