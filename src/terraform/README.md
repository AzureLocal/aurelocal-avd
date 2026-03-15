# Terraform – AVD on Azure Local

Terraform configuration for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
src/terraform/
├── versions.tf                # Provider version pins (azurerm + azapi)
├── variables.tf               # Input variable declarations
├── locals.tf                  # Shared locals (tags, VM name list)
├── control-plane.tf           # AVD control plane resources (RG, LAW, KV, host pool, app group, workspace)
├── session-hosts.tf           # Session-host VMs on Azure Local (Arc VMs, NICs, extensions)
├── outputs.tf                 # Outputs
└── terraform.tfvars.example   # Example variable values
```

---

## Prerequisites

- Terraform >= 1.5: [Install](https://developer.hashicorp.com/terraform/downloads)
- AzureRM provider >= 3.75, AzAPI provider >= 1.10 (pinned in `versions.tf`)
- Azure CLI logged in: `az login`

---

## Deployment

```bash
cd src/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

terraform init
terraform plan
terraform apply
```

---

## Destroying Resources

```bash
terraform destroy
```

---

> **Note**: Never commit `terraform.tfvars` (it is `.gitignore`d). Use environment variables or a secrets manager for sensitive values.
