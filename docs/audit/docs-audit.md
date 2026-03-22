# Documentation Audit — azurelocal-avd

Generated: 2026-03-22

## Overview
This audit lists existing documentation files in `azurelocal-avd` and recommended edits/additions to align with Epic #8 documentation plan.

## Existing key docs (reviewed)
- `docs/architecture.md` — High-level architecture (exists)
- `docs/guides/avd-deployment-guide.md` — Deployment guide (exists)
- `docs/reference/monitoring-queries.md` — Monitoring KQLs (exists)
- `docs/reference/tool-parity-matrix.md` — Tool parity (exists)
- `docs/reference/variable-mapping.md` — Variable mapping (exists)

## Recommended new pages (stubs created)
- `docs/architecture/deep-design.md` — deeper design (created)
- `docs/architecture/fslogix-integration.md` — FSLogix integration (created)
- `docs/reference/host-pool-options.md` — host-pool config options (created)
- `docs/guides/rdapps.md` — RemoteApps publishing guide (created)
- `docs/operations/defender-operations.md` — Defender & security (created)
- `docs/operations/cost-management.md` — cost management (created)
- `docs/diagrams/README.md` — diagrams guidance (created)
- `docs/README.md` — docs index (created)

## Files that should be updated (high priority)
- `docs/architecture.md` — add links to new deep-design and FSLogix pages; include decision flows and diagram references
- `docs/guides/avd-deployment-guide.md` — update steps to reference new RBAC/FSLogix/host-pool docs
- `docs/reference/monitoring-queries.md` — expand with LAW table mappings and cost-related KQL samples
- `mkdocs.yml` — ensure `docs/diagrams` included and `mkdocs-drawio` plugin is configured (CI currently installs mkdocs-drawio)
- `.github/workflows/validate-repo-structure.yml` — ensure checks accept new files; add docs lint/check step if not present

## Reusable assets in `azurelocal-sofs-fslogix`
(Do NOT edit SOFS repo; reference or copy exported PNGs)
- `docs/assets/diagrams/sofs-deployment-phases.drawio` (draw.io source)
- `docs/assets/images/sofs-deployment-phases.png` (exported image)
- `docs/architecture/storage-design.md`, `capacity-planning.md`, `scenarios.md`, `avd-considerations.md`

## Next recommended actions (short-term)
1. Review and accept the created stubs in a docs PR.
2. Copy selected exported PNGs from `azurelocal-sofs-fslogix` into `docs/diagrams/` in this repo (no edits to SOFS repo).
3. Populate `deep-design.md` and `fslogix-integration.md` with content adapted from SOFS docs and Microsoft references.
4. Add draw.io source files in `docs/diagrams/` for AVD-specific diagrams (control-plane, network, DR) and export PNG/SVG.

## Contacts / Owners
- Docs owner: maintainers of `azurelocal-avd` (please assign an architecture reviewer)

