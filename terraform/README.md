# Terraform – AVD on Azure Local

Terraform configurations for deploying Azure Virtual Desktop on Azure Local.

---

## Folder Structure

```
terraform/
├── control-plane/
│   ├── main.tf                 # AVD control-plane resources
│   ├── variables.tf            # Input variable declarations
│   ├── outputs.tf              # Outputs
│   ├── versions.tf             # Provider version pins
│   └── terraform.tfvars.example
└── session-hosts/
    ├── main.tf                 # Session-host VMs on Azure Local
    ├── variables.tf
    ├── outputs.tf
    ├── versions.tf
    └── terraform.tfvars.example
```

---

## Prerequisites

- Terraform >= 1.5: [Install](https://developer.hashicorp.com/terraform/downloads)
- AzureRM provider >= 3.75 (pinned in `versions.tf`)
- Azure CLI logged in: `az login`

---

## Control Plane Deployment

```bash
cd terraform/control-plane
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

---

## Session Host Deployment

```bash
cd terraform/session-hosts
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
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
