# Diagrams

This directory will contain draw.io sources and exported images for architecture diagrams.

Guidance:
- Prefer draw.io `.drawio` source files for maintainability.
- Export PNG and SVG for MkDocs rendering.
- For SOFS-specific diagrams we will reference the companion repo assets and copy needed exported PNGs into this directory.

Current references (external):
- SOFS deployment phases (source): `../..../azurelocal-sofs-fslogix/docs/assets/diagrams/sofs-deployment-phases.drawio`
- SOFS exported PNG: `https://raw.githubusercontent.com/AzureLocal/azurelocal-sofs-fslogix/feature/epic-59-completion/docs/assets/images/sofs-deployment-phases.png`

TODO:
- Add local copies of exported PNGs into this directory as part of the next PR (do not modify SOFS repo).
- Add `sofs-deployment-phases.drawio` copy as a base and adapt for AVD control-plane diagrams.
