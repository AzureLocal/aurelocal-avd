# Contributing Guide

Thank you for your interest in contributing to **azurelocal-avd**!

---

## Code of Conduct

Be respectful and constructive. This project follows the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Stable, production-ready code |
| `dev` | Integration branch for feature work |
| `feature/<name>` | Individual feature or fix branches |
| `hotfix/<name>` | Urgent production fixes |

All changes go through a Pull Request targeting `dev`, which is then merged to `main` on release.

---

## Getting Started

1. Fork the repository and clone your fork.
2. Create a feature branch: `git checkout -b feature/my-improvement`
3. Make your changes (see conventions below).
4. Push and open a PR against `dev`.

---

## Coding Conventions

### PowerShell

- Use `[CmdletBinding(SupportsShouldProcess)]` on all deployment scripts.
- Set `Set-StrictMode -Version Latest` and `$ErrorActionPreference = "Stop"` at the top.
- Use approved PowerShell verbs (`New-`, `Set-`, `Remove-`, `Test-`).
- Include comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`).
- Use `Write-Host` with `-ForegroundColor` for status messages; use `Write-Verbose` for debug detail.
- Support a `parameters.ps1` file pattern (see `parameters.example.ps1` in `src/powershell/`).

### Azure CLI / Bash

- Use `set -euo pipefail` at the top of every script.
- Source a `parameters.sh` file for environment-specific values.
- Use `az` resource existence checks before creating resources (idempotent deployments).
- Echo section headers and success/failure messages.

### Bicep

- Use `targetScope = 'subscription'` for control-plane templates (resource group creation) and `targetScope = 'resourceGroup'` for session-host templates.
- Break resources into modules or separate `.bicep` resource files.
- Include `@description()` decorators on all parameters.
- Provide a `*.bicepparam.example` file for every `main.bicep`.
- Prefer `existing` resource references over hard-coded resource IDs where possible.

### ARM

- Use `$schema` version `2019-04-01` for subscription-scope templates and `2022-09-01` for resource-group scope.
- Include a `parameters.example.json` alongside every `azuredeploy.json`.
- Do not store secrets in parameter files; use `"reference": { "keyVault": ... }`.

### Terraform

- Pin provider versions in `versions.tf`.
- Use `variables.tf` for all input variables with `description` and `type`.
- Provide `outputs.tf` with meaningful outputs.
- Include `terraform.tfvars.example` but **never** commit `terraform.tfvars` (it is `.gitignore`d).
- Use `terraform fmt` before committing.

### Ansible

- Roles follow the standard Ansible role directory layout.
- Use `defaults/main.yml` for overridable defaults.
- Tasks should be idempotent (check before acting).
- Use Ansible Vault for secrets; do not commit plaintext passwords.

---

## Pull Request Checklist

- [ ] Code follows the conventions above for the relevant tool.
- [ ] A `parameters.example.*` or `*.example` file is provided for any new deployment.
- [ ] README updated if new files or parameters were added.
- [ ] No secrets, passwords, or subscription IDs committed.
- [ ] Tested against a real Azure / Azure Local environment (note testing notes in the PR).

---

## Reporting Issues

Open a GitHub Issue with:
- A clear description of the problem.
- The tool / folder affected.
- Steps to reproduce.
- Relevant error messages or logs.
