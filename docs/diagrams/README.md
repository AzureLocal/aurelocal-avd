# Diagrams

This directory contains architecture diagram sources and rendered assets for AVD on Azure Local documentation.

## Standards
- Use draw.io (`.drawio`) for editable sources.
- Keep exported `.png` and `.svg` for MkDocs compatibility.
- Name diagrams by function and scope (for example `control-plane`, `network-flow`, `dr-recovery`).

## Included assets
- `control-plane.drawio`
- `avd-reference-architecture.drawio`
- `avd-reference-architecture.png`
- `sofs-deployment-phases.drawio`
- `sofs-deployment-phases.png`

## Workflow
1. Edit diagram in draw.io.
2. Export PNG and SVG to this folder.
3. Update `docs/diagrams/index.md` if a new asset is added.
