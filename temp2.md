# AVD Deep Audit and Epic 8 Re-Baseline (Execution Record)

## Scope

Deep scan coverage:

- docs: architecture, deployment guide, standards, variable reference
- examples: CI/CD pipeline examples
- config: example variable contract and JSON schema
- src implementations: PowerShell, Terraform, Bicep, ARM, Ansible
- portfolio governance: Epic #8 and open child issues #10, #12, #14, #16, #18, #21, #24, #26, #28, #30, #32, #34

Audit objective:

- identify parity/contract drift with evidence
- convert findings into issue-ready acceptance criteria
- prevent re-close without reproducible proof artifacts

---

## Executive Result

Epic #8 is structurally healthy (parent open, children open), but implementation and documentation still diverge in key areas:

1. central contract claim is stronger than runtime enforcement across toolchains
2. docs/examples include stale or conflicting execution paths
3. Ansible and CI/CD claims overstate current end-to-end parity
4. schema validates shape but not enough behavior-level constraints
5. issue bodies need explicit tool-boundary and evidence gates before execution starts

Net: Epic is actionable, but must be re-baselined before any child should close.

---

## Evidence Matrix (Deep Scan)

### A) Central Contract Drift (`config/variables.yml` vs runtime)

Evidence:

- docs/standards/automation.md states `config/variables.yml` is the only source and all tool files are derived
- docs/reference/variables.md repeats single-source-of-truth claim for every tool
- src/powershell/New-AVDControlPlane.ps1 and src/powershell/New-AVDSessionHosts.ps1 consume `parameters.ps1` variables directly (`-ParametersFile`), not `config/variables.yml`
- src/powershell/parameters.example.ps1 uses a separate flat model (`$ResourceGroupName`, `$HostPoolName`, etc.)
- src/terraform/README.md and src/terraform/terraform.tfvars.example rely on direct `terraform.tfvars` editing
- src/ansible/roles/* expect role vars (`avd_*`, `azure_*`) with no enforced YAML contract bridge in repo
- src/bicep/Deploy-AVDSessionHosts.ps1 is the strongest contract implementation path because it reads `config/variables.yml`

Assessment: Partial compliance.

### B) Docs and Example Path Drift

Evidence:

- examples/pipelines/azure-devops/*.yml.example uses `infrastructure/bicep/...` paths that do not exist in repo (actual path root is `src/bicep/...`)
- examples/pipelines/github-actions/deploy-avd.yml.example uses `az deployment group create` for `src/bicep/session-hosts.bicep` while that template is subscription-scope in this repo pattern
- docs/guides/avd-deployment-guide.md shows direct manual parameter workflows (`parameters.ps1`, `terraform.tfvars`, `*.bicepparam`) that conflict with strict single-source claim

Assessment: Non-compliant for path/flow consistency.

### C) Ansible Claim vs Depth

Evidence:

- src/ansible/playbooks/site.yml orchestrates two localhost roles only
- src/ansible/roles/avd-control-plane/tasks/main.yml provisions control-plane resources and token handling
- src/ansible/roles/avd-session-hosts/tasks/main.yml provisions resources/extensions but does not show complete validation lifecycle, rollback, or host readiness assertions matching epic-scale end-to-end claim

Assessment: Partial to non-compliant versus issue narrative "end-to-end" expectations.

### D) Schema Constraint Gaps

Evidence:

- config/schema/variables.schema.json enforces structural requirements and enums
- missing behavior constraints for cross-field logic such as:
  - host pool type conditional requirements (`Pooled` vs `Personal`)
  - `keyvault://` URI pattern enforcement for secrets
  - stronger resource ID format validation for Azure Local IDs

Assessment: Partial compliance.

### E) Epic Governance

Evidence:

- Epic #8 and all target children are currently open
- issue bodies still describe broad goals but need specific closure gate language aligned to current repo reality

Assessment: Structurally compliant, execution criteria under-specified.

---

## Compliance Snapshot

Legend:

- Compliant: implementation + docs + issue contract aligned
- Partial: mostly aligned with explicit caveats needed
- Non-compliant: claim and implementation materially conflict

| Area | Status |
|---|---|
| Epic/child topology in place | Compliant |
| Single-source config runtime enforcement across all tools | Partial |
| PowerShell parity with central config model | Partial |
| Terraform parity with central config model | Partial |
| Bicep path and orchestration parity | Partial |
| ARM parity claims and documentation depth | Partial |
| Ansible end-to-end claim depth | Partial to Non-compliant |
| Pipeline example correctness | Non-compliant |
| Schema behavior-level constraints | Partial |
| Evidence-based close criteria in issues | Partial |

---

## Epic 8 Re-Baseline Content (Apply to Parent)

Required addendum for Epic #8:

1. Define contract mode per tool explicitly:
	- strict direct (`config/variables.yml` consumed directly)
	- derived (`tool params generated from canonical config`)
	- temporary transitional (`tool-native params accepted until bridge delivered`)
2. Define deployment boundary split:
	- control plane in Azure
	- session hosts on Azure Local
3. Add hard close gate:
	- no child closes without reproducible command log and artifact references
4. Add dependency references:
	- SOFS storage/profile stream
	- Toolkit variable registry and parity tracking

---

## Child Issue Rewrite Map (What each child must require)

### #10 Config and schema

- add conditional schema rules and URI/resource-id patterns
- define canonical-to-tool mapping contract table
- output: validated sample config plus negative test cases

### #12 PowerShell

- state current `parameters.ps1` mode as transitional
- require bridge to canonical YAML or deterministic generator
- output: command transcript + idempotent rerun evidence

### #14 Terraform

- require explicit delegation boundaries and canonical mapping doc
- enforce output inventory contract for downstream tools
- output: plan/apply evidence and drift-safe rerun

### #16 Ansible

- reduce "end-to-end" claim to current scope until parity criteria pass
- add host readiness and post-config validation tasks
- output: play recap + validation checks + failure-mode behavior

### #18 Bicep

- keep as primary canonical path while others converge
- require parity matrix references for non-Bicep differences
- output: control/session deployments with what-if evidence

### #21 ARM

- explicitly mark generated/derived relationship from Bicep where applicable
- require parity test list with Bicep outputs
- output: deployment evidence and known deviations table

### #24 Monitoring and Defender

- anchor required telemetry outputs and diagnostic settings artifacts
- output: KQL or resource evidence proving diagnostics enabled

### #26 Identity and RBAC

- define least-privilege assignment scope per plane
- output: role assignment evidence and validation commands

### #28 Image and FSLogix

- define dependency on SOFS profile storage readiness
- output: image selection/config proof + profile path validation

### #30 Documentation

- correct stale paths (`infrastructure/...` -> `src/...`) and scope statements
- publish caveated capability matrix reflecting real current parity
- output: docs PR references and rendered site checks

### #32 CI/CD

- fix pipeline examples to actual repo paths and template scopes
- ensure deployment commands match template target scope
- output: dry-run logs and successful sample run

### #34 Validation matrix

- define mandatory scenario matrix and per-tool pass/fail gates
- enforce artifact checklist before any child closure
- output: consolidated validation report with reproducible commands

---

## Execution Order

Recommended sequence:

1. #10 contract/schema
2. #30 docs and #32 pipelines (remove stale guidance early)
3. #12/#14/#16 tool contract convergence
4. #18/#21 parity confirmation
5. #24/#26/#28 platform integration
6. #34 final matrix and closure evidence

---

## Immediate Next Actions

1. update Epic #8 body with re-baseline + hard close gates
2. rewrite open child issues #10/#12/#14/#16/#18/#21/#24/#26/#28/#30/#32/#34 with contract/parity/evidence/dependency sections
3. set Project 3 status: Epic in progress, children todo
4. start remediation execution from #10
