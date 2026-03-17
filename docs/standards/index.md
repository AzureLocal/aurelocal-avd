# Standards

This repository follows the **org-wide AzureLocal standards** maintained on the central documentation site.

!!! info "Central Standards"
    The full standards suite is at [azurelocal.cloud/standards](https://azurelocal.cloud/standards/).
    This section provides the key rules adapted for the AVD on Azure Local solution.

---

## Standards Pages

| Standard | Local Page | Central Reference |
|----------|-----------|------------------|
| Documentation | [Documentation Standards](documentation.md) | [Full Reference](https://azurelocal.cloud/standards/documentation/documentation-standards) |
| Scripting | [Scripting Standards](scripting.md) | [Full Reference](https://azurelocal.cloud/standards/scripting/scripting-standards) |
| Variables | [Variable Standards](variables.md) | [Full Reference](https://azurelocal.cloud/standards/variable-management/) |
| Naming Conventions | [Naming Conventions](naming.md) | [Full Reference](https://azurelocal.cloud/standards/documentation/naming-conventions) |
| Solutions | [Solution Standards](solutions.md) | [Full Reference](https://azurelocal.cloud/standards/solutions/solution-development-standard) |
| Infrastructure | [Infrastructure Standards](infrastructure.md) | [Full Reference](https://azurelocal.cloud/standards/infrastructure/) |
| Automation | [Automation Interoperability](automation.md) | [Full Reference](https://azurelocal.cloud/standards/scripting/scripting-framework) |
| Examples & IIC | [Examples & IIC](examples.md) | [Full Reference](https://azurelocal.cloud/standards/fictional-company-policy) |

---

## References

- [Variable Reference](../reference/variables.md) — Per-variable catalog for this repo
- [Repository Structure](https://azurelocal.cloud/standards/repo-structure) — Required file layout

---

## Repo-Specific Conventions

This repository follows additional conventions specific to the AVD on Azure Local solution:

- **IaC tooling**: Terraform, Bicep, ARM, PowerShell, Ansible
- **Config file**: `config/variables.example.yml` — see [Variable Reference](../reference/variables.md)
- **Fictional company**: Infinite Improbability Corp (IIC) — see [IIC Policy](examples.md)
