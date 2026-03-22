# Docs Validation and Review Checklist

Use this checklist for every docs-only PR.

## Automated validation
- Confirm all markdown links resolve.
- Confirm `mkdocs.yml` nav entries point to existing files.
- Confirm each diagram source (`.drawio`) has a rendered image (`.png` and/or `.svg`) when referenced in docs.
- Confirm no temporary placeholder text remains (`TODO`, `TBD`, `placeholder`) unless explicitly marked as owner action.

## Content quality checks
- Verify all configuration examples align with `config/variables.yml` naming.
- Verify AVD terminology is consistent (`host pool`, `application group`, `workspace`).
- Verify references point to current Microsoft docs.
- Verify security guidance aligns with least-privilege RBAC patterns.

## Required sign-offs
- Architecture owner: required for architecture, networking, identity, FSLogix, DR, and host pool behavior changes.
- Security owner: required for Defender and RBAC guidance changes.
- Operations owner: required for monitoring, cost, and runbook updates.

## PR template prompts
- What docs changed and why?
- What diagrams were updated, and were exports regenerated?
- What assumptions remain environment-specific?
- Which owner approved architecture/security content?